import AppIntents
import Foundation

struct SetLedPowerIntent: AppIntent {
    static var title: LocalizedStringResource = "LED Aç/Kapat"
    static var description = IntentDescription("LED lambayı açar veya kapatır")
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Durum")
    var isOn: Bool
    
    func perform() async throws -> some IntentResult {
        let bleManager = LedBleManager.shared
        
        guard bleManager.isConnected else {
            throw IntentError.notConnected
        }
        
        if isOn {
            bleManager.powerOn()
        } else {
            bleManager.powerOff()
        }
        
        return .result()
    }
}

struct TurnOnLedIntent: AppIntent {
    static var title: LocalizedStringResource = "LED Aç"
    static var description = IntentDescription("LED lambayı açar")
    static var openAppWhenRun: Bool = false
    
    static var parameterSummary: some ParameterSummary {
        Summary("LED lambayı aç")
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
        
        bleManager.powerOn()
        return .result()
    }
}

struct TurnOffLedIntent: AppIntent {
    static var title: LocalizedStringResource = "LED Kapat"
    static var description = IntentDescription("LED lambayı kapatır")
    static var openAppWhenRun: Bool = false
    
    static var parameterSummary: some ParameterSummary {
        Summary("LED lambayı kapat")
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
        
        bleManager.powerOff()
        return .result()
    }
}


