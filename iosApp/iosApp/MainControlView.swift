import SwiftUI
import SharedLedController

struct MainControlView: View {
    @ObservedObject var bleManager = LedBleManager.shared
    @State private var selectedColor: Color = .white
    @State private var brightness: Double = 100
    @State private var isPowerOn = true
    @State private var favoriteColors: [(r: Int, g: Int, b: Int)] = []
    @State private var brightnessUpdateTask: Task<Void, Never>?
    
    var body: some View {
        ZStack {
            // Arka plan gradient
            ClioTheme.backgroundDark
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header - Renault Clio Badge
                        HStack(spacing: 12) {
                            Image("cliorange")
                                .resizable()
                                .renderingMode(.original)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 132, height: 132)
                                .shadow(color: ClioTheme.primaryOrange.opacity(0.4), radius: 8, x: 0, y: 4)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Text("Renault Clio")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(ClioTheme.textPrimary)
                                    Text("Alpine")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(ClioTheme.primaryOrange)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(ClioTheme.primaryOrange.opacity(0.2))
                                        )
                                }
                                
                                // Connection Status
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(bleManager.isConnected ? Color.green : Color.red)
                                        .frame(width: 10, height: 10)
                                        .shadow(color: bleManager.isConnected ? Color.green.opacity(0.6) : Color.red.opacity(0.6), radius: 4)
                                    Text(bleManager.connectionStatus)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(ClioTheme.textSecondary)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .clioCard()
                        
                        // Cihaz Seç Butonu (bağlı değilken göster)
                        if !bleManager.isConnected {
                            NavigationLink(destination: DeviceSelectionView()) {
                                HStack {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                    Text("Cihaz Seç")
                                }
                                .frame(maxWidth: .infinity)
                                .clioButton()
                            }
                        }
                        
                        // Ambiyans Önizleme Alanı
                        AmbiancePreviewView(selectedColor: $selectedColor) { newColor in
                            // Renk değiştiğinde BLE'ye gönder
                            selectedColor = newColor
                            if bleManager.isConnected {
                                let uiColor = UIColor(newColor)
                                var r: CGFloat = 0
                                var g: CGFloat = 0
                                var b: CGFloat = 0
                                var a: CGFloat = 0
                                uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
                                bleManager.setColor(
                                    r: Int(r * 255),
                                    g: Int(g * 255),
                                    b: Int(b * 255)
                                )
                            }
                        }
                        .padding(.vertical, 12)
                        .clioCard()
                        
                        // Ambiyans Kartı - Sadece Color Picker
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "paintpalette.fill")
                                    .foregroundStyle(ClioTheme.primaryGradient)
                                    .font(.system(size: 18))
                                Text("Renk Paleti")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(ClioTheme.textPrimary)
                            }
                            
                            // Color Picker
                            HStack {
                                ZStack {
                                    ColorPicker("Renk", selection: $selectedColor)
                                        .labelsHidden()
                                        .frame(width: 60, height: 60)
                                    
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 1.0, green: 0.0, blue: 0.0),
                                                    Color(red: 0.0, green: 1.0, blue: 0.0),
                                                    Color(red: 0.0, green: 0.0, blue: 1.0),
                                                    Color(red: 1.0, green: 0.0, blue: 1.0),
                                                    Color(red: 1.0, green: 1.0, blue: 0.0),
                                                    Color(red: 1.0, green: 0.5, blue: 0.0)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            Circle()
                                                .stroke(ClioTheme.primaryOrange.opacity(0.3), lineWidth: 2)
                                        )
                                        .overlay(
                                            Image(systemName: "paintpalette.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(.white)
                                                .shadow(color: .black.opacity(0.3), radius: 2)
                                        )
                                        .allowsHitTesting(false)
                                        .shadow(color: Color.blue.opacity(0.6), radius: 8, x: 0, y: 4)
                                        .shadow(color: Color.blue.opacity(0.4), radius: 4, x: 0, y: 2)
                                }
                                .frame(width: 68, height: 68)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Özel Renk Seç")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(ClioTheme.textPrimary)
                                    Text("Palete dokunarak istediğiniz rengi seçin")
                                        .font(.system(size: 12))
                                        .foregroundColor(ClioTheme.textSecondary)
                                }
                                
                                Spacer()
                            }
                            .onChange(of: selectedColor) { newColor in
                                if bleManager.isConnected {
                                    let uiColor = UIColor(newColor)
                                    var r: CGFloat = 0
                                    var g: CGFloat = 0
                                    var b: CGFloat = 0
                                    var a: CGFloat = 0
                                    uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
                                    bleManager.setColor(
                                        r: Int(r * 255),
                                        g: Int(g * 255),
                                        b: Int(b * 255)
                                    )
                                }
                            }
                        }
                        .clioCard()
                        
                        // Favorites Section
                        if !favoriteColors.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(ClioTheme.primaryGradient)
                                        .font(.system(size: 18))
                                    Text("Favoriler")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(ClioTheme.textPrimary)
                                }
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(Array(favoriteColors.enumerated()), id: \.offset) { index, fav in
                                            VStack(spacing: 8) {
                                                Button(action: {
                                                    setQuickColor(r: fav.r, g: fav.g, b: fav.b)
                                                }) {
                                                    Circle()
                                                        .fill(Color(
                                                            red: Double(fav.r) / 255.0,
                                                            green: Double(fav.g) / 255.0,
                                                            blue: Double(fav.b) / 255.0
                                                        ))
                                                        .frame(width: 60, height: 60)
                                                        .overlay(
                                                            Circle()
                                                                .stroke(ClioTheme.primaryOrange.opacity(0.3), lineWidth: 2)
                                                        )
                                                        .shadow(color: Color(
                                                            red: Double(fav.r) / 255.0,
                                                            green: Double(fav.g) / 255.0,
                                                            blue: Double(fav.b) / 255.0
                                                        ).opacity(0.5), radius: 8)
                                                }
                                                
                                                Button(action: {
                                                    removeFavorite(r: fav.r, g: fav.g, b: fav.b)
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.red)
                                                        .font(.system(size: 20))
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }
                            .clioCard()
                        }
                        
                        // Add to Favorites Button
                        if bleManager.isConnected {
                            Button(action: {
                                addCurrentColorToFavorites()
                            }) {
                                HStack {
                                    Image(systemName: "star.fill")
                                    Text("Favorilere Ekle")
                                }
                                .frame(maxWidth: .infinity)
                                .clioButton()
                            }
                            .disabled(!SharedLedController.shared.canAddMoreFavorites())
                            .opacity(SharedLedController.shared.canAddMoreFavorites() ? 1.0 : 0.5)
                        }
                        
                        // Brightness Slider
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "sun.max.fill")
                                    .foregroundStyle(ClioTheme.primaryGradient)
                                    .font(.system(size: 18))
                                Text("Parlaklık")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(ClioTheme.textPrimary)
                                Spacer()
                                Text("\(Int(brightness))%")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(ClioTheme.primaryGradient)
                            }
                            
                            Slider(value: $brightness, in: 0...100, step: 1)
                                .tint(ClioTheme.primaryOrange)
                                .onChange(of: brightness) { newValue in
                                    if bleManager.isConnected {
                                        // İptal et önceki görev
                                        brightnessUpdateTask?.cancel()
                                        
                                        // Debounce: Slider hareket ederken bekle, durduktan 150ms sonra gönder
                                        brightnessUpdateTask = Task {
                                            try? await Task.sleep(nanoseconds: 150_000_000) // 150ms
                                            guard !Task.isCancelled else { return }
                                            await MainActor.run {
                                                if bleManager.isConnected {
                                                    bleManager.setBrightness(level: Int(newValue))
                                                }
                                            }
                                        }
                                    }
                                }
                        }
                        .clioCard()
                        
                        // Power Toggle
                        Button(action: {
                            isPowerOn.toggle()
                            if bleManager.isConnected {
                                if isPowerOn {
                                    bleManager.powerOn()
                                } else {
                                    bleManager.powerOff()
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: isPowerOn ? "lightbulb.fill" : "lightbulb")
                                    .font(.system(size: 20))
                                Text(isPowerOn ? "LED Açık" : "LED Kapalı")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .clioButton(isPrimary: isPowerOn)
                        }
                        .disabled(!bleManager.isConnected)
                        .opacity(bleManager.isConnected ? 1.0 : 0.5)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
        }
        .navigationTitle("Ayak LED Kontrolü")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ClioTheme.backgroundDark, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: DeviceSelectionView()) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundStyle(ClioTheme.primaryGradient)
                }
            }
        }
        .onAppear {
            loadFavorites()
            // Başlangıçta parlaklığı senkronize et
            brightness = Double(bleManager.currentBrightness)
        }
        .onChange(of: bleManager.currentBrightness) { newBrightness in
            // Dışarıdan parlaklık değiştiğinde (örneğin intent'lerden) slider'ı güncelle
            if abs(brightness - Double(newBrightness)) > 1 {
                brightness = Double(newBrightness)
            }
        }
    }
    
    private func setQuickColor(r: Int, g: Int, b: Int) {
        if bleManager.isConnected {
            bleManager.setColor(r: r, g: g, b: b)
            selectedColor = Color(
                red: Double(r) / 255.0,
                green: Double(g) / 255.0,
                blue: Double(b) / 255.0
            )
        }
    }
    
    private func addCurrentColorToFavorites() {
        let uiColor = UIColor(selectedColor)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rInt = Int(r * 255)
        let gInt = Int(g * 255)
        let bInt = Int(b * 255)
        
        // Kotlin Int maps to Int32 in Swift
        if SharedLedController.shared.addFavorite(r: Int32(rInt), g: Int32(gInt), b: Int32(bInt)) {
            loadFavorites()
        }
    }
    
    private func removeFavorite(r: Int, g: Int, b: Int) {
        // Kotlin Int maps to Int32 in Swift
        SharedLedController.shared.removeFavorite(r: Int32(r), g: Int32(g), b: Int32(b))
        loadFavorites()
    }
    
    private func loadFavorites() {
        let favorites = SharedLedController.shared.getFavorites()
        // Kotlin List<Triple> is converted to Swift Array
        var result: [(r: Int, g: Int, b: Int)] = []
        for triple in favorites {
            guard let first = triple.first,
                  let second = triple.second,
                  let third = triple.third else {
                continue
            }
            let r = Int(truncating: first)
            let g = Int(truncating: second)
            let b = Int(truncating: third)
            result.append((r: r, g: g, b: b))
        }
        favoriteColors = result
    }
}

struct QuickColorButton: View {
    let color: Color
    let name: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(ClioTheme.primaryOrange.opacity(0.3), lineWidth: 2)
                        )
                        .shadow(color: color.opacity(0.6), radius: 8, x: 0, y: 4)
                        .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 2)
                }
                .frame(width: 68, height: 68)
                Text(name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ClioTheme.textPrimary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainControlView()
}

