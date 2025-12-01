import AppIntents
import Foundation

enum BrightnessLevel: String, AppEnum {
    case veryLow = "veryLow"
    case low = "low"
    case medium = "medium"
    case high = "high"
    case max = "max"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Parlaklık Seviyesi"
    
    static var caseDisplayRepresentations: [BrightnessLevel: DisplayRepresentation] = [
        .veryLow: "Çok Düşük",
        .low: "Düşük",
        .medium: "Orta",
        .high: "Yüksek",
        .max: "Maksimum"
    ]
    
    var value: Int {
        switch self {
        case .veryLow: return 20
        case .low: return 40
        case .medium: return 60
        case .high: return 80
        case .max: return 100
        }
    }
}

struct SetLedBrightnessIntent: AppIntent {
    static var title: LocalizedStringResource = "LED Parlaklık Ayarla"
    static var description = IntentDescription("LED lambanın parlaklığını ayarlar")
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Parlaklık Seviyesi")
    var level: BrightnessLevel
    
    func perform() async throws -> some IntentResult {
        let bleManager = LedBleManager.shared
        
        guard bleManager.isConnected else {
            throw IntentError.notConnected
        }
        
        bleManager.setBrightness(level: level.value)
        
        return .result()
    }
}

struct IncreaseBrightnessIntent: AppIntent {
    static var title: LocalizedStringResource = "LED Parlaklığı Artır"
    static var description = IntentDescription("LED lambanın parlaklığını artırır")
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult {
        let bleManager = LedBleManager.shared
        
        if !bleManager.isConnected {
            bleManager.scanAndConnectToSavedDevice()
            try await Task.sleep(nanoseconds: 2_000_000_000)
            guard bleManager.isConnected else {
                throw IntentError.notConnected
            }
        }
        
        let newBrightness = min(100, bleManager.currentBrightness + 20)
        bleManager.setBrightness(level: newBrightness)
        return .result()
    }
}

struct DecreaseBrightnessIntent: AppIntent {
    static var title: LocalizedStringResource = "LED Parlaklığı Azalt"
    static var description = IntentDescription("LED lambanın parlaklığını azaltır")
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult {
        let bleManager = LedBleManager.shared
        
        if !bleManager.isConnected {
            bleManager.scanAndConnectToSavedDevice()
            try await Task.sleep(nanoseconds: 2_000_000_000)
            guard bleManager.isConnected else {
                throw IntentError.notConnected
            }
        }
        
        let newBrightness = max(0, bleManager.currentBrightness - 20)
        bleManager.setBrightness(level: newBrightness)
        return .result()
    }
}

struct SetMaxBrightnessIntent: AppIntent {
    static var title: LocalizedStringResource = "LED Parlaklığı Maksimum Yap"
    static var description = IntentDescription("LED lambanın parlaklığını maksimum yapar")
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult {
        let bleManager = LedBleManager.shared
        
        if !bleManager.isConnected {
            bleManager.scanAndConnectToSavedDevice()
            try await Task.sleep(nanoseconds: 2_000_000_000)
            guard bleManager.isConnected else {
                throw IntentError.notConnected
            }
        }
        
        bleManager.setBrightness(level: 100)
        return .result()
    }
}


