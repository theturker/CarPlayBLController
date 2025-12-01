import SwiftUI

struct ContentView: View {
    @ObservedObject var bleManager = LedBleManager.shared
    @State private var lastConnectedState = false
    
    var body: some View {
        // Show main control if connected or connecting (to prevent flickering during connection)
        // Keep showing main control for a short time after disconnect to prevent immediate screen change
        if bleManager.isConnected || bleManager.isConnecting || lastConnectedState {
            MainControlView()
                .onAppear {
                    if bleManager.isConnected {
                        lastConnectedState = true
                    }
                }
                .onChange(of: bleManager.isConnected) { connected in
                    if connected {
                        lastConnectedState = true
                    } else {
                        // Delay going back to device selection by 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            if !bleManager.isConnected && !bleManager.isConnecting {
                                lastConnectedState = false
                            }
                        }
                    }
                }
        } else {
            DeviceSelectionView()
        }
    }
}
