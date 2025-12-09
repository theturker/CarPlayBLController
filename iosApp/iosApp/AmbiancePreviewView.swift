import SwiftUI

struct AmbiancePreviewView: View {
    @Binding var selectedColor: Color
    let onColorChanged: (Color) -> Void
    
    @State private var previewColor: Color = .white
    @State private var selectedColorIndex: Int? = nil
    
    // RGB değerlerinden direkt Color oluşturuluyor - sistem renkleri yerine
    private let quickColors: [(color: Color, name: String, r: Int, g: Int, b: Int)] = [
        (Color(red: 1.0, green: 0.0, blue: 0.0), "Kırmızı", 255, 0, 0),
        (Color(red: 0.0, green: 0.0, blue: 1.0), "Mavi", 0, 0, 255),
        (Color(red: 0.0, green: 1.0, blue: 0.0), "Yeşil", 0, 255, 0),
        (Color(red: 1.0, green: 0.0, blue: 1.0), "Mor", 255, 0, 255),
        (Color(red: 1.0, green: 1.0, blue: 1.0), "Beyaz", 255, 255, 255),
        (Color(red: 0.953, green: 0.451, blue: 0.149), "Turuncu", 243, 115, 38)
    ]
    
    private func updateSelectedColorIndex() {
        // Seçili rengi hızlı renklerle karşılaştır
        let uiColor = UIColor(selectedColor)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rInt = Int(r * 255)
        let gInt = Int(g * 255)
        let bInt = Int(b * 255)
        
        // Hızlı renklerle eşleşen var mı kontrol et (tolerans: 10)
        for (index, item) in quickColors.enumerated() {
            if abs(item.r - rInt) < 10 && abs(item.g - gInt) < 10 && abs(item.b - bInt) < 10 {
                selectedColorIndex = index
                return
            }
        }
        selectedColorIndex = nil // Özel renk seçilmiş
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Önizleme Alanı
            ZStack(alignment: .center) {
                // Altta kokpit görseli
                Image("maxresdefault")
                    .resizable()
                    .renderingMode(.original)
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)
                
                // Üstte ayak altı maskesi (renkli) - sağ ve sol boşluk ile
                HStack(spacing: 0) {
                    Spacer()
                        .frame(width: 50)
                    
                    ZStack {
                        // Maske görseli - renkli overlay
                        Image("footwellmask")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(previewColor)
                            .frame(height: 200)
                            .blendMode(.screen)
                            .opacity(0.8)
                        
                        // Ekstra glow efekti
                        Image("footwellmask")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(previewColor)
                            .frame(height: 200)
                            .blur(radius: 8)
                            .opacity(0.4)
                    }
                    .cornerRadius(12)
                    .animation(.easeInOut(duration: 0.4), value: previewColor)
                    
                    Spacer()
                        .frame(width: 50)
                }
            }
            .frame(height: 200)
            .shadow(color: previewColor.opacity(0.4), radius: 16, x: 0, y: 6)
            .shadow(color: ClioTheme.primaryOrange.opacity(0.2), radius: 8, x: 0, y: 3)
            
            // Renk Paleti Butonları
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(quickColors.enumerated()), id: \.offset) { index, item in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                selectedColorIndex = index
                                // RGB değerlerinden direkt Color oluştur - sistem renklerinden değil
                                let colorFromRgb = Color(
                                    red: Double(item.r) / 255.0,
                                    green: Double(item.g) / 255.0,
                                    blue: Double(item.b) / 255.0
                                )
                                previewColor = colorFromRgb
                                selectedColor = colorFromRgb
                                
                                // Callback ile renk değişikliğini bildir
                                onColorChanged(colorFromRgb)
                            }
                        }) {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(item.color)
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    selectedColorIndex == index ? ClioTheme.primaryOrange : Color.clear,
                                                    lineWidth: 3
                                                )
                                        )
                                        .shadow(
                                            color: selectedColorIndex == index ? item.color.opacity(0.6) : item.color.opacity(0.3),
                                            radius: selectedColorIndex == index ? 8 : 4,
                                            x: 0,
                                            y: selectedColorIndex == index ? 4 : 2
                                        )
                                    
                                    if selectedColorIndex == index {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                            .shadow(color: .black.opacity(0.3), radius: 2)
                                    }
                                }
                                .frame(width: 56, height: 56)
                                
                                Text(item.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(ClioTheme.textPrimary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .onAppear {
            previewColor = selectedColor
            // Mevcut rengi hızlı renklerden biriyle eşleştir
            updateSelectedColorIndex()
        }
        .onChange(of: selectedColor) { newColor in
            // Dışarıdan renk değiştiğinde (örneğin ColorPicker'dan)
            withAnimation(.easeInOut(duration: 0.4)) {
                previewColor = newColor
                updateSelectedColorIndex()
            }
        }
    }
}

#Preview {
    AmbiancePreviewView(selectedColor: .constant(.red)) { color in
        print("Renk değişti: \(color)")
    }
    .padding()
    .background(ClioTheme.backgroundDark)
}

