import AppIntents

enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case notConnected
    
    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notConnected:
            return "LED cihazına bağlı değilsiniz"
        }
    }
}


