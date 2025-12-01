import SwiftUI

struct DeviceSelectionView: View {
    @ObservedObject var bleManager = LedBleManager.shared
    @State private var isScanning = false
    
    var body: some View {
        NavigationView {
            VStack {
                if bleManager.discoveredDevices.isEmpty && !isScanning {
                    VStack(spacing: 20) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Cihaz bulunamadı")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Taramayı başlatmak için butona basın")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    List(bleManager.discoveredDevices) { device in
                        Button(action: {
                            bleManager.connect(to: device)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(device.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(device.id.uuidString)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if bleManager.isConnected && bleManager.connectedPeripheral?.identifier == device.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Spacer()
                
                // Show all devices toggle
                Toggle(isOn: $bleManager.showAllDevices) {
                    Text("Tüm cihazları göster")
                        .font(.subheadline)
                }
                .padding(.horizontal)
                .onChange(of: bleManager.showAllDevices) { _ in
                    if isScanning {
                        bleManager.stopScanning()
                        bleManager.startScanning()
                    }
                }
                
                Button(action: {
                    if isScanning {
                        bleManager.stopScanning()
                        isScanning = false
                    } else {
                        bleManager.startScanning()
                        isScanning = true
                    }
                }) {
                    HStack {
                        Image(systemName: isScanning ? "stop.circle.fill" : "magnifyingglass")
                        Text(isScanning ? "Taramayı Durdur" : "Cihazları Tara")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isScanning ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Cihaz Seçimi")
            .onAppear {
                bleManager.startScanning()
                isScanning = true
            }
            .onDisappear {
                bleManager.stopScanning()
                isScanning = false
            }
        }
    }
}

#Preview {
    DeviceSelectionView()
}

