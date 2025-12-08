import SwiftUI

struct DeviceSelectionView: View {
    @ObservedObject var bleManager = LedBleManager.shared
    @State private var isScanning = false
    
    var body: some View {
        ZStack {
            // Arka plan gradient
            ClioTheme.backgroundDark
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if bleManager.discoveredDevices.isEmpty && !isScanning {
                        Spacer()
                        VStack(spacing: 24) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 80))
                                .foregroundStyle(ClioTheme.primaryGradient)
                                .symbolEffect(.pulse, options: .repeating)
                            
                            VStack(spacing: 8) {
                                Text("Cihaz bulunamadı")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(ClioTheme.textPrimary)
                                Text("Taramayı başlatmak için butona basın")
                                    .font(.system(size: 16))
                                    .foregroundColor(ClioTheme.textSecondary)
                            }
                        }
                        .padding()
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(bleManager.discoveredDevices) { device in
                                    Button(action: {
                                        bleManager.connect(to: device)
                                    }) {
                                        HStack(spacing: 16) {
                                            // Device icon
                                            ZStack {
                                                Circle()
                                                    .fill(ClioTheme.primaryOrange.opacity(0.2))
                                                    .frame(width: 50, height: 50)
                                                Image(systemName: "antenna.radiowaves.left.and.right")
                                                    .font(.system(size: 20))
                                                    .foregroundStyle(ClioTheme.primaryGradient)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(device.name)
                                                    .font(.system(size: 18, weight: .semibold))
                                                    .foregroundColor(ClioTheme.textPrimary)
                                                Text(device.id.uuidString)
                                                    .font(.system(size: 12, design: .monospaced))
                                                    .foregroundColor(ClioTheme.textSecondary)
                                                    .lineLimit(1)
                                            }
                                            
                                            Spacer()
                                            
                                            if bleManager.isConnected && bleManager.connectedPeripheral?.identifier == device.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.green)
                                                    .shadow(color: .green.opacity(0.5), radius: 4)
                                            } else if bleManager.isConnecting && bleManager.connectedPeripheral?.identifier == device.id {
                                                ProgressView()
                                                    .tint(ClioTheme.primaryOrange)
                                            } else {
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(ClioTheme.textSecondary)
                                            }
                                        }
                                        .padding()
                                        .clioCard()
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    }
                    
                    VStack(spacing: 16) {
                        // Show all devices toggle
                        HStack {
                            Image(systemName: "list.bullet")
                                .foregroundStyle(ClioTheme.primaryGradient)
                            Toggle(isOn: $bleManager.showAllDevices) {
                                Text("Tüm cihazları göster")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(ClioTheme.textPrimary)
                            }
                            .tint(ClioTheme.primaryOrange)
                        }
                        .padding()
                        .clioCard()
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
                            .clioButton(isPrimary: !isScanning)
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
        }
        .navigationTitle("Cihaz Seçimi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ClioTheme.backgroundDark, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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

#Preview {
    DeviceSelectionView()
}

