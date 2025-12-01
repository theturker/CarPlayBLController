import AppIntents
import Foundation

struct SetLedRedIntent: AppIntent {
    static var title: LocalizedStringResource = "Ambiyans Işığını Kırmızı Yap"
    static var description = IntentDescription("Ambiyans ışığını kırmızı yapar")
    static var openAppWhenRun: Bool = false
    
    static var parameterSummary: some ParameterSummary {
        Summary("Ambiyans ışığını kırmızı yap")
    }
    
    func perform() async throws -> some IntentResult {
        let bleManager = LedBleManager.shared
        
        // If not connected, try to reconnect to last device
        if !bleManager.isConnected {
            print("⚠️ Not connected, attempting to reconnect...")
            bleManager.scanAndConnectToSavedDevice()
            
            // Wait a bit for connection
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            guard bleManager.isConnected else {
                throw IntentError.notConnected
            }
        }
        
        bleManager.setColor(r: 255, g: 0, b: 0)
        return .result()
    }
}

struct SetLedBlueIntent: AppIntent {
    static var title: LocalizedStringResource = "Ambiyans Işığını Mavi Yap"
    static var description = IntentDescription("Ambiyans ışığını mavi yapar")
    static var openAppWhenRun: Bool = false
    
    static var parameterSummary: some ParameterSummary {
        Summary("Ambiyans ışığını mavi yap")
    }
    
    func perform() async throws -> some IntentResult {
        let bleManager = LedBleManager.shared
        
        if !bleManager.isConnected {
            bleManager.scanAndConnectToSavedDevice()
            try await Task.sleep(nanoseconds: 2_000_000_000)
            guard bleManager.isConnected else {
                throw IntentError.notConnected
            }
        }
        
        bleManager.setColor(r: 0, g: 0, b: 255)
        return .result()
    }
}

struct SetLedGreenIntent: AppIntent {
    static var title: LocalizedStringResource = "Ambiyans Işığını Yeşil Yap"
    static var description = IntentDescription("Ambiyans ışığını yeşil yapar")
    static var openAppWhenRun: Bool = false
    
    static var parameterSummary: some ParameterSummary {
        Summary("Ambiyans ışığını yeşil yap")
    }
    
    func perform() async throws -> some IntentResult {
        let bleManager = LedBleManager.shared
        
        if !bleManager.isConnected {
            bleManager.scanAndConnectToSavedDevice()
            try await Task.sleep(nanoseconds: 2_000_000_000)
            guard bleManager.isConnected else {
                throw IntentError.notConnected
            }
        }
        
        bleManager.setColor(r: 0, g: 255, b: 0)
        return .result()
    }
}

struct SetLedPurpleIntent: AppIntent {
    static var title: LocalizedStringResource = "Ambiyans Işığını Mor Yap"
    static var description = IntentDescription("Ambiyans ışığını mor yapar")
    static var openAppWhenRun: Bool = false
    
    static var parameterSummary: some ParameterSummary {
        Summary("Ambiyans ışığını mor yap")
    }
    
    func perform() async throws -> some IntentResult {
        let bleManager = LedBleManager.shared
        
        if !bleManager.isConnected {
            bleManager.scanAndConnectToSavedDevice()
            try await Task.sleep(nanoseconds: 2_000_000_000)
            guard bleManager.isConnected else {
                throw IntentError.notConnected
            }
        }
        
        bleManager.setColor(r: 255, g: 0, b: 255)
        return .result()
    }
}

struct SetLedWhiteIntent: AppIntent {
    static var title: LocalizedStringResource = "Ambiyans Işığını Beyaz Yap"
    static var description = IntentDescription("Ambiyans ışığını beyaz yapar")
    static var openAppWhenRun: Bool = false
    
    static var parameterSummary: some ParameterSummary {
        Summary("Ambiyans ışığını beyaz yap")
    }
    
    func perform() async throws -> some IntentResult {
        let bleManager = LedBleManager.shared
        
        if !bleManager.isConnected {
            bleManager.scanAndConnectToSavedDevice()
            try await Task.sleep(nanoseconds: 2_000_000_000)
            guard bleManager.isConnected else {
                throw IntentError.notConnected
            }
        }
        
        bleManager.setColor(r: 255, g: 255, b: 255)
        return .result()
    }
}


