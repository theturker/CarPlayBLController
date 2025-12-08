import SwiftUI

struct ContentView: View {
    @ObservedObject var bleManager = LedBleManager.shared
    
    var body: some View {
        NavigationView {
            // Her zaman MainControlView göster, bağlı değilse içinde cihaz seç butonu var
            MainControlView()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
