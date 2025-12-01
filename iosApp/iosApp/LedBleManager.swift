import Foundation
import UIKit
import CoreBluetooth
import Combine
import SharedLedController

// Background task management for keeping BLE connection alive
extension UIApplication {
    static var isInBackground: Bool {
        return shared.applicationState == .background
    }
}

final class LedBleManager: NSObject, ObservableObject {
    static let shared = LedBleManager()
    
    // Published properties
    @Published var isConnected: Bool = false
    @Published var isConnecting: Bool = false
    @Published var currentColor: UIColor = .white
    @Published var currentBrightness: Int = 100
    @Published var discoveredDevices: [DiscoveredDevice] = []
    @Published var connectionStatus: String = "Bağlı değil"
    
    // BLE UUIDs
    private let serviceUUID = CBUUID(string: "0000fff0-0000-1000-8000-00805f9b34fb")
    private let writeCharacteristicUUID = CBUUID(string: "0000fff3-0000-1000-8000-00805f9b34fb")
    
    // BLE components
    private var centralManager: CBCentralManager!
    private(set) var connectedPeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    
    // Connection timeout - increased for slow devices
    private var connectionTimer: Timer?
    private let connectionTimeout: TimeInterval = 30.0
    
    // Keep-alive timer to prevent connection timeout
    private var keepAliveTimer: Timer?
    private let keepAliveInterval: TimeInterval = 2.0 // Send keep-alive every 2 seconds (very frequent to prevent timeout)
    
    // Background task identifier for keeping app alive
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    // Device name patterns (optional, for filtering)
    private let deviceNamePatterns = ["ELK-BLEDOM", "Lotus", "LED", "BLEDOM", "BLE", "RGB", "Light", "Lamp", "MELK"]
    
    // Show all devices option
    @Published var showAllDevices: Bool = false
    
    // UserDefaults keys
    private let lastDeviceIdentifierKey = "lastDeviceIdentifier"
    private let lastDeviceNameKey = "lastDeviceName"
    
    struct DiscoveredDevice: Identifiable {
        let id: UUID
        let name: String
        let peripheral: CBPeripheral
    }
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            print("Bluetooth is not powered on")
            return
        }
        
        discoveredDevices.removeAll()
        // Always scan without service filter first to find all devices
        // Service filtering can miss devices that don't advertise the service
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        connectionStatus = "Taranıyor..."
        print("Tarama başlatıldı - Tüm cihazlar taranıyor")
    }
    
    func stopScanning() {
        centralManager.stopScan()
        if !isConnected {
            connectionStatus = "Bağlı değil"
        }
    }
    
    func connect(to device: DiscoveredDevice) {
        stopScanning()
        
        // Check if device is already connected
        let retrievedPeripherals = centralManager.retrievePeripherals(withIdentifiers: [device.id])
        if let retrieved = retrievedPeripherals.first {
            print("📱 Device state: \(retrieved.state.rawValue)")
            switch retrieved.state {
            case .connected:
                print("✅ Device already connected, using existing connection")
                connectedPeripheral = retrieved
                retrieved.delegate = self
                isConnecting = false
                isConnected = true
                connectionStatus = "Bağlı"
                saveLastDevice(peripheral: retrieved)
                retrieved.discoverServices([serviceUUID])
                startKeepAlive()
                return
            case .connecting:
                print("⏳ Device is already connecting, waiting...")
                connectedPeripheral = retrieved
                retrieved.delegate = self
                isConnecting = true
                connectionStatus = "Bağlanıyor..."
                return
            default:
                // Disconnect first if in any other state
                if retrieved.state != .disconnected {
                    print("🔄 Disconnecting device in state \(retrieved.state.rawValue) before reconnecting...")
                    centralManager.cancelPeripheralConnection(retrieved)
                    // Wait a bit before reconnecting
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        self?.performConnection(to: device)
                    }
                    return
                }
            }
        }
        
        performConnection(to: device)
    }
    
    private func performConnection(to device: DiscoveredDevice) {
        isConnecting = true
        connectedPeripheral = device.peripheral
        connectedPeripheral?.delegate = self
        
        print("📋 Connection details:")
        print("   Name: \(device.name)")
        print("   UUID: \(device.id)")
        print("   Peripheral state: \(device.peripheral.state.rawValue)")
        
        // Start connection timeout
        connectionTimer?.invalidate()
        connectionTimer = Timer.scheduledTimer(withTimeInterval: connectionTimeout, repeats: false) { [weak self] _ in
            guard let self = self, self.isConnecting else { return }
            print("⏱️ Connection timeout after \(self.connectionTimeout) seconds")
            print("   Peripheral state: \(self.connectedPeripheral?.state.rawValue ?? -1)")
            if let peripheral = self.connectedPeripheral {
                self.centralManager.cancelPeripheralConnection(peripheral)
            }
            self.isConnecting = false
            self.connectionStatus = "Bağlantı zaman aşımı - cihaz yanıt vermiyor"
            self.connectedPeripheral = nil
            
            // Suggest user to check device
            print("💡 İpucu:")
            print("   - Cihazın açık olduğundan emin olun")
            print("   - Cihazın başka bir telefona/tablete bağlı olmadığından emin olun")
            print("   - Cihazı kapatıp açmayı deneyin")
            print("   - iPhone'u yeniden başlatmayı deneyin")
        }
        
        // Connect without options - some BLE devices don't work well with options
        print("🔗 Attempting connection...")
        centralManager.connect(device.peripheral, options: nil)
        connectionStatus = "Bağlanıyor..."
        
        // Check connection progress after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self, self.isConnecting else { return }
            if let peripheral = self.connectedPeripheral {
                print("📊 Connection progress check:")
                print("   State after 2s: \(peripheral.state.rawValue)")
                print("   State description: \(self.stateDescription(peripheral.state))")
            }
        }
    }
    
    private func stateDescription(_ state: CBPeripheralState) -> String {
        switch state {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        case .disconnecting: return "Disconnecting"
        @unknown default: return "Unknown"
        }
    }
    
    func disconnect() {
        print("Manually disconnecting...")
        connectionTimer?.invalidate()
        connectionTimer = nil
        stopKeepAlive()
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        isConnecting = false
        isConnected = false
        connectionStatus = "Bağlı değil"
        connectedPeripheral = nil
        writeCharacteristic = nil
    }
    
    // MARK: - Keep-Alive
    
    private func startKeepAlive() {
        stopKeepAlive()
        // Only start keep-alive if we have a characteristic
        guard let characteristic = writeCharacteristic else {
            print("⚠️ Cannot start keep-alive - characteristic not ready")
            return
        }
        
        guard isConnected else {
            print("⚠️ Cannot start keep-alive - not connected")
            return
        }
        
        print("✅ Keep-alive timer started (interval: \(keepAliveInterval)s)")
        // Use RunLoop to keep timer active even in background
        keepAliveTimer = Timer.scheduledTimer(withTimeInterval: keepAliveInterval, repeats: true) { [weak self] timer in
            guard let self = self, self.isConnected, let characteristic = self.writeCharacteristic else {
                print("🛑 Stopping keep-alive - connection lost or characteristic missing")
                self?.stopKeepAlive()
                return
            }
            
            // Send a minimal command to keep connection alive
            // Use brightness command with current brightness to avoid visible changes
            let brightness = self.currentBrightness
            let brightnessValue = Int((Double(brightness) / 100.0) * 255.0)
            let kotlinBytes = SharedLedController.shared.getBrightnessCommandBytes(brightness: Int32(brightnessValue))
            let data = kotlinBytes.toData()
            self.connectedPeripheral?.writeValue(data, for: characteristic, type: .withoutResponse)
            
            // Renew background task periodically
            self.renewBackgroundTask()
        }
        
        // Add timer to common run loop modes so it works in background
        if let timer = keepAliveTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private func stopKeepAlive() {
        keepAliveTimer?.invalidate()
        keepAliveTimer = nil
    }
    
    // MARK: - Background Task Management
    
    private func startBackgroundTask() {
        endBackgroundTask()
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        print("📱 Background task started: \(backgroundTask.rawValue)")
    }
    
    private func renewBackgroundTask() {
        // Renew background task to keep it active
        if backgroundTask != .invalid {
            endBackgroundTask()
        }
        startBackgroundTask()
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            print("📱 Ending background task: \(backgroundTask.rawValue)")
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    func scanAndConnectToSavedDevice() {
        guard let identifierString = UserDefaults.standard.string(forKey: lastDeviceIdentifierKey),
              let identifier = UUID(uuidString: identifierString) else {
            startScanning()
            return
        }
        
        // Try to find the saved device in already discovered peripherals
        if let peripheral = centralManager.retrievePeripherals(withIdentifiers: [identifier]).first {
            let device = DiscoveredDevice(
                id: identifier,
                name: UserDefaults.standard.string(forKey: lastDeviceNameKey) ?? "Kayıtlı Cihaz",
                peripheral: peripheral
            )
            connect(to: device)
        } else {
            // Start scanning and try to connect when found
            startScanning()
        }
    }
    
    func setColor(r: Int, g: Int, b: Int) {
        guard isConnected else {
            print("⚠️ Not connected - cannot set color")
            return
        }
        
        guard let characteristic = writeCharacteristic else {
            print("⚠️ Write characteristic not available yet - waiting...")
            // Try to discover again if characteristic is missing
            if let peripheral = connectedPeripheral {
                peripheral.discoverServices([serviceUUID])
            }
            return
        }
        
        // Get command bytes from KMP
        // Kotlin Int maps to Int32 in Swift
        let kotlinBytes = SharedLedController.shared.getColorCommandBytes(r: Int32(r), g: Int32(g), b: Int32(b))
        let data = kotlinBytes.toData()
        
        // Use withoutResponse for faster writes
        connectedPeripheral?.writeValue(data, for: characteristic, type: .withoutResponse)
        currentColor = UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: 1.0)
    }
    
    func setBrightness(level: Int) {
        guard isConnected, let characteristic = writeCharacteristic else {
            print("Not connected or characteristic not available")
            return
        }
        
        // Map 0-100 to 0-255
        let brightnessValue = Int((Double(level) / 100.0) * 255.0)
        
        // Get command bytes from KMP
        // Kotlin Int maps to Int32 in Swift
        let kotlinBytes = SharedLedController.shared.getBrightnessCommandBytes(brightness: Int32(brightnessValue))
        let data = kotlinBytes.toData()
        
        // Use withoutResponse for faster writes
        connectedPeripheral?.writeValue(data, for: characteristic, type: .withoutResponse)
        currentBrightness = level
    }
    
    func powerOn() {
        guard isConnected, let characteristic = writeCharacteristic else {
            print("Not connected or characteristic not available")
            return
        }
        
        let kotlinBytes = SharedLedController.shared.getPowerOnCommandBytes()
        let data = kotlinBytes.toData()
        
        // Use withoutResponse for faster writes
        connectedPeripheral?.writeValue(data, for: characteristic, type: .withoutResponse)
    }
    
    func powerOff() {
        guard isConnected, let characteristic = writeCharacteristic else {
            print("Not connected or characteristic not available")
            return
        }
        
        let kotlinBytes = SharedLedController.shared.getPowerOffCommandBytes()
        let data = kotlinBytes.toData()
        
        // Use withoutResponse for faster writes
        connectedPeripheral?.writeValue(data, for: characteristic, type: .withoutResponse)
    }
    
    func write(_ bytes: [UInt8]) {
        guard isConnected, let characteristic = writeCharacteristic else {
            print("Not connected or characteristic not available")
            return
        }
        
        let data = Data(bytes)
        // Use withoutResponse for faster writes
        connectedPeripheral?.writeValue(data, for: characteristic, type: .withoutResponse)
    }
    
    // MARK: - Private Methods
    
    private func saveLastDevice(peripheral: CBPeripheral) {
        UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: lastDeviceIdentifierKey)
        UserDefaults.standard.set(peripheral.name ?? "Bilinmeyen Cihaz", forKey: lastDeviceNameKey)
    }
    
    private func isTargetDevice(_ peripheral: CBPeripheral) -> Bool {
        guard let name = peripheral.name else { return false }
        return deviceNamePatterns.contains { pattern in
            name.localizedCaseInsensitiveContains(pattern)
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension LedBleManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
            scanAndConnectToSavedDevice()
        case .poweredOff:
            print("Bluetooth is powered off")
            connectionStatus = "Bluetooth kapalı"
        case .unauthorized:
            print("Bluetooth is unauthorized")
            connectionStatus = "Bluetooth izni gerekli"
        case .unsupported:
            print("Bluetooth is unsupported")
            connectionStatus = "Bluetooth desteklenmiyor"
        default:
            print("Bluetooth state: \(central.state.rawValue)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Check if device has the target service UUID in advertisement data
        var hasServiceUUID = false
        if let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            hasServiceUUID = serviceUUIDs.contains(serviceUUID)
        }
        
        // Check if device name matches known patterns
        let matchesName = isTargetDevice(peripheral)
        
        // If scanning with service UUID filter, all discovered devices are valid
        // If showAllDevices is true, show all devices
        // Otherwise, show devices that match name patterns or have the service UUID in advertisement
        let isValidDevice = showAllDevices || hasServiceUUID || matchesName
        
        if isValidDevice {
            let deviceName = peripheral.name ?? "Bilinmeyen Cihaz"
            let device = DiscoveredDevice(
                id: peripheral.identifier,
                name: deviceName,
                peripheral: peripheral
            )
            
            // Avoid duplicates
            if !discoveredDevices.contains(where: { $0.id == device.id }) {
                discoveredDevices.append(device)
                print("Bulunan cihaz: \(deviceName) - UUID: \(peripheral.identifier) - RSSI: \(RSSI)")
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("✅✅✅ Connected to \(peripheral.name ?? "device") ✅✅✅")
        print("   UUID: \(peripheral.identifier)")
        print("   State: \(peripheral.state.rawValue)")
        connectionTimer?.invalidate()
        connectionTimer = nil
        isConnecting = false
        isConnected = true
        connectionStatus = "Bağlı"
        saveLastDevice(peripheral: peripheral)
        
        // Start background task to keep connection alive
        startBackgroundTask()
        
        // Discover services with timeout
        print("🔍 Discovering services...")
        print("   Looking for service: \(serviceUUID.uuidString)")
        peripheral.discoverServices([serviceUUID])
        
        // Don't start keep-alive yet - wait for characteristic to be found
        
        // Set a timeout for service discovery
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self, self.isConnected, self.writeCharacteristic == nil else { return }
            print("⚠️ Service discovery timeout - characteristic not found yet")
            // Don't disconnect, just log - some devices take longer
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("❌ Disconnected from \(peripheral.name ?? "device")")
        connectionTimer?.invalidate()
        connectionTimer = nil
        stopKeepAlive()
        endBackgroundTask()
        isConnecting = false
        isConnected = false
        connectionStatus = "Bağlı değil"
        connectedPeripheral = nil
        writeCharacteristic = nil
        
        if let error = error {
            print("Disconnect error: \(error.localizedDescription)")
            print("Error code: \((error as NSError).code)")
            connectionStatus = "Bağlantı hatası: \(error.localizedDescription)"
            
            // If timeout error, try to reconnect automatically
            if (error as NSError).code == 6 { // Connection timeout
                print("🔄 Attempting to reconnect after timeout...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.scanAndConnectToSavedDevice()
                }
            }
        } else {
            print("Disconnected without error (possibly device went out of range or turned off)")
            // Try to reconnect even if no error (connection might have dropped)
            print("🔄 Attempting to reconnect...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                guard let self = self, !self.isConnected else { return }
                self.scanAndConnectToSavedDevice()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("❌ Failed to connect: \(error?.localizedDescription ?? "unknown error")")
        connectionTimer?.invalidate()
        connectionTimer = nil
        isConnecting = false
        connectionStatus = "Bağlantı başarısız"
        isConnected = false
        connectedPeripheral = nil
        
        if let error = error {
            print("Error code: \((error as NSError).code)")
            print("Error domain: \((error as NSError).domain)")
        }
        
        // Try to reconnect after a short delay if it was a timeout
        if let error = error, (error as NSError).code == 10 { // Connection timeout
            print("🔄 Retrying connection in 2 seconds...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self = self, !self.isConnected else { return }
                // Find the device again and retry
                if let device = self.discoveredDevices.first(where: { $0.id == peripheral.identifier }) {
                    self.connect(to: device)
                }
            }
        }
    }
}

// MARK: - CBPeripheralDelegate

extension LedBleManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("❌ Service discovery error: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services, !services.isEmpty else {
            print("⚠️ No services found")
            return
        }
        
        print("Found \(services.count) service(s)")
        var foundTargetService = false
        
        for service in services {
            print("  - Service: \(service.uuid.uuidString)")
            if service.uuid == serviceUUID {
                foundTargetService = true
                print("✅ Found target service, discovering characteristics...")
                peripheral.discoverCharacteristics([writeCharacteristicUUID], for: service)
            }
        }
        
        if !foundTargetService {
            print("⚠️ Target service not found. Available services:")
            for service in services {
                print("    \(service.uuid.uuidString)")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("❌ Characteristic discovery error: \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics, !characteristics.isEmpty else {
            print("⚠️ No characteristics found for service")
            return
        }
        
        print("Found \(characteristics.count) characteristic(s)")
        var foundTargetCharacteristic = false
        
        for characteristic in characteristics {
            print("  - Characteristic: \(characteristic.uuid.uuidString)")
            if characteristic.uuid == writeCharacteristicUUID {
                writeCharacteristic = characteristic
                foundTargetCharacteristic = true
                print("✅ Found write characteristic - ready to send commands!")
                connectionStatus = "Bağlı ve hazır"
                
                // Start keep-alive immediately after characteristic is found
                print("🔄 Starting keep-alive timer...")
                startKeepAlive()
                
                // Send an initial command to establish connection
                // This helps prevent immediate timeout
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let self = self, self.isConnected else { return }
                    print("📤 Sending initial keep-alive command...")
                    if let characteristic = self.writeCharacteristic {
                        let brightness = self.currentBrightness
                        let brightnessValue = Int((Double(brightness) / 100.0) * 255.0)
                        let kotlinBytes = SharedLedController.shared.getBrightnessCommandBytes(brightness: Int32(brightnessValue))
                        let data = kotlinBytes.toData()
                        self.connectedPeripheral?.writeValue(data, for: characteristic, type: .withoutResponse)
                    }
                }
            }
        }
        
        if !foundTargetCharacteristic {
            print("⚠️ Target write characteristic not found. Available characteristics:")
            for characteristic in characteristics {
                print("    \(characteristic.uuid.uuidString)")
            }
            connectionStatus = "Bağlı (karakteristik bulunamadı)"
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("❌ Write error: \(error.localizedDescription)")
            // Don't disconnect on write error - just log it
        } else {
            print("✅ Write successful")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("⚠️ Notification state update error: \(error.localizedDescription)")
        }
    }
    
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        print("Peripheral name updated: \(peripheral.name ?? "unknown")")
    }
}

