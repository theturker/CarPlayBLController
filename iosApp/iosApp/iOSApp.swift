import SwiftUI

@main
struct iOSApp: App {
    @StateObject private var bleManager = LedBleManager.shared
    
    init() {
        // Initialize KMP framework if needed
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bleManager)
        }
    }
}
