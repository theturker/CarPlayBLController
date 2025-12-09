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
            ClioTheme.backgroundDark
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    headerCard
                    deviceSelectionButton
                    ambiancePreviewCard
                    colorPickerCard
                    favoritesSection
                    addToFavoritesButton
                    brightnessCard
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Alpine Ambiyans")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ClioTheme.backgroundDark, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
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
                    Image(systemName: isPowerOn ? "lightbulb.fill" : "lightbulb")
                        .foregroundColor(isPowerOn ? ClioTheme.primaryOrange : ClioTheme.textSecondary)
                        .font(.system(size: 20, weight: .semibold))
                }
                .disabled(!bleManager.isConnected)
                .opacity(bleManager.isConnected ? 1.0 : 0.5)
            }
            
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
    
    // MARK: - View Components
    
    private var headerCard: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 20) {
                Image("cliorange")
                    .resizable()
                    .renderingMode(.original)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 110, height: 110)
                    .shadow(color: ClioTheme.primaryOrange.opacity(0.4), radius: 8, x: 0, y: 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("Renault Clio")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(ClioTheme.textPrimary)
                        Image("alpinebadge")
                            .resizable()
                            .renderingMode(.original)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                    }
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(bleManager.isConnected ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                            .shadow(color: bleManager.isConnected ? Color.green.opacity(0.6) : Color.red.opacity(0.6), radius: 4)
                        Text(bleManager.connectionStatus)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ClioTheme.textSecondary)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 6)
            
            // Badge - sağ üst köşe
            Image("badge")
                .resizable()
                .renderingMode(.original)
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30)
                .padding(.top, 5)
                .padding(.trailing, 5)
        }
        .clioCard()
    }
    
    @ViewBuilder
    private var deviceSelectionButton: some View {
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
    }
    
    private var ambiancePreviewCard: some View {
        AmbiancePreviewView(selectedColor: $selectedColor) { newColor in
            selectedColor = newColor
            if bleManager.isConnected {
                let (r, g, b) = extractRGB(from: newColor)
                bleManager.setColor(r: r, g: g, b: b)
            }
        }
        .padding(.vertical, 12)
        .clioCard()
    }
    
    private var colorPickerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "paintpalette.fill")
                    .foregroundStyle(ClioTheme.primaryGradient)
                    .font(.system(size: 18))
                Text("Renk Paleti")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ClioTheme.textPrimary)
            }
            
            HStack {
                colorPickerButton
                
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
                    let (r, g, b) = extractRGB(from: newColor)
                    bleManager.setColor(r: r, g: g, b: b)
                }
            }
        }
        .clioCard()
    }
    
    private var colorPickerButton: some View {
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
    }
    
    @ViewBuilder
    private var favoritesSection: some View {
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
                            favoriteColorItem(fav: fav)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .clioCard()
        }
    }
    
    private func favoriteColorItem(fav: (r: Int, g: Int, b: Int)) -> some View {
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
    
    @ViewBuilder
    private var addToFavoritesButton: some View {
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
    }
    
    private var brightnessCard: some View {
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
                    handleBrightnessChange(newValue)
                }
        }
        .clioCard()
    }
    
    // MARK: - Helper Methods
    
    private func handleBrightnessChange(_ newValue: Double) {
        if bleManager.isConnected {
            brightnessUpdateTask?.cancel()
            brightnessUpdateTask = Task {
                try? await Task.sleep(nanoseconds: 150_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    if bleManager.isConnected {
                        bleManager.setBrightness(level: Int(newValue))
                    }
                }
            }
        }
    }
    
    // RGB değerlerini Color'dan güvenli bir şekilde çıkarır
    private func extractRGB(from color: Color) -> (r: Int, g: Int, b: Int) {
        let uiColor = UIColor(color)
        
        // CGColor kullanarak daha güvenli RGB çıkarımı
        let cgColor = uiColor.cgColor
        let components = cgColor.components ?? []
        
        // Eğer components varsa ve yeterli sayıda ise (en az 3: R, G, B)
        if components.count >= 3 {
            // Grayscale renkler için (1 component) veya RGB renkler için (3+ components)
            let r: CGFloat
            let g: CGFloat
            let b: CGFloat
            
            if components.count == 1 {
                // Grayscale
                let gray = components[0]
                r = gray
                g = gray
                b = gray
            } else {
                // RGB
                r = components[0]
                g = components[1]
                b = components[2]
            }
            
            return (
                r: min(255, max(0, Int(r * 255))),
                g: min(255, max(0, Int(g * 255))),
                b: min(255, max(0, Int(b * 255)))
            )
        }
        
        // Fallback: UIColor'ın getRed metodunu kullan
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        if uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return (
                r: min(255, max(0, Int(r * 255))),
                g: min(255, max(0, Int(g * 255))),
                b: min(255, max(0, Int(b * 255)))
            )
        }
        
        // Son çare: varsayılan olarak beyaz döndür
        return (r: 255, g: 255, b: 255)
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
        let (r, g, b) = extractRGB(from: selectedColor)
        
        // Kotlin Int maps to Int32 in Swift
        if SharedLedController.shared.addFavorite(r: Int32(r), g: Int32(g), b: Int32(b)) {
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

