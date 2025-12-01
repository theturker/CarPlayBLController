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
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Connection Status
                    HStack {
                        Circle()
                            .fill(bleManager.isConnected ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        Text(bleManager.connectionStatus)
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    if !bleManager.isConnected {
                        NavigationLink(destination: DeviceSelectionView()) {
                            Text("Cihaz Seç")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    
                    // Color Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Renk Seç")
                            .font(.headline)
                        ColorPicker("Renk", selection: $selectedColor)
                            .frame(height: 50)
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
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // Quick Color Buttons
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Hızlı Renkler")
                            .font(.headline)
                        HStack(spacing: 12) {
                            QuickColorButton(color: .red, name: "Kırmızı") {
                                setQuickColor(r: 255, g: 0, b: 0)
                            }
                            QuickColorButton(color: .blue, name: "Mavi") {
                                setQuickColor(r: 0, g: 0, b: 255)
                            }
                            QuickColorButton(color: .green, name: "Yeşil") {
                                setQuickColor(r: 0, g: 255, b: 0)
                            }
                            QuickColorButton(color: .purple, name: "Mor") {
                                setQuickColor(r: 255, g: 0, b: 255)
                            }
                            QuickColorButton(color: .white, name: "Beyaz") {
                                setQuickColor(r: 255, g: 255, b: 255)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // Favorites Section
                    if !favoriteColors.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Favoriler")
                                .font(.headline)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Array(favoriteColors.enumerated()), id: \.offset) { index, fav in
                                        Button(action: {
                                            setQuickColor(r: fav.r, g: fav.g, b: fav.b)
                                        }) {
                                            VStack {
                                                Circle()
                                                    .fill(Color(
                                                        red: Double(fav.r) / 255.0,
                                                        green: Double(fav.g) / 255.0,
                                                        blue: Double(fav.b) / 255.0
                                                    ))
                                                    .frame(width: 50, height: 50)
                                                Button(action: {
                                                    removeFavorite(r: fav.r, g: fav.g, b: fav.b)
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.red)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
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
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(!SharedLedController.shared.canAddMoreFavorites())
                    }
                    
                    // Brightness Slider
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Parlaklık: \(Int(brightness))%")
                            .font(.headline)
                        Slider(value: $brightness, in: 0...100, step: 1)
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
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
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
                            Text(isPowerOn ? "Açık" : "Kapalı")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isPowerOn ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!bleManager.isConnected)
                }
                .padding()
            }
            .navigationTitle("LED Kontrol")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: DeviceSelectionView()) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
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
            VStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 50, height: 50)
                Text(name)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
    }
}

#Preview {
    MainControlView()
}

