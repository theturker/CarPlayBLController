import SwiftUI

// Renault Clio Turuncu & Alpine Paketi Teması
struct ClioTheme {
    // Ana turuncu renk (Renault Clio turuncu)
    static let primaryOrange = Color(red: 0.95, green: 0.45, blue: 0.15) // #F27326 benzeri
    static let primaryOrangeDark = Color(red: 0.85, green: 0.35, blue: 0.10)
    static let primaryOrangeLight = Color(red: 1.0, green: 0.55, blue: 0.25)
    
    // Gradient renkler
    static let gradientStart = Color(red: 0.95, green: 0.45, blue: 0.15)
    static let gradientEnd = Color(red: 0.90, green: 0.35, blue: 0.10)
    
    // Alpine paketi - siyah ve gri tonları
    static let alpineBlack = Color(red: 0.05, green: 0.05, blue: 0.05)
    static let alpineDarkGray = Color(red: 0.15, green: 0.15, blue: 0.15)
    static let alpineGray = Color(red: 0.25, green: 0.25, blue: 0.25)
    static let alpineLightGray = Color(red: 0.35, green: 0.35, blue: 0.35)
    
    // Vurgu renkleri
    static let accentSilver = Color(red: 0.75, green: 0.75, blue: 0.75)
    static let accentGold = Color(red: 0.85, green: 0.70, blue: 0.40)
    
    // Arka plan
    static let backgroundDark = Color(red: 0.08, green: 0.08, blue: 0.10)
    static let backgroundCard = Color(red: 0.12, green: 0.12, blue: 0.14)
    
    // Metin renkleri
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.7, green: 0.7, blue: 0.7)
    
    // Gradient
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [gradientStart, gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Glow efekti için
    static func glowColor(_ color: Color) -> some View {
        color
            .shadow(color: color.opacity(0.6), radius: 8)
            .shadow(color: color.opacity(0.4), radius: 16)
    }
}

// Özel görünüm modifikatörleri
struct ClioCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ClioTheme.backgroundCard)
                    .shadow(color: ClioTheme.primaryOrange.opacity(0.2), radius: 8, x: 0, y: 4)
            )
    }
}

struct ClioButtonStyle: ButtonStyle {
    var isPrimary: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                Group {
                    if isPrimary {
                        ClioTheme.primaryGradient
                    } else {
                        LinearGradient(
                            colors: [ClioTheme.alpineDarkGray, ClioTheme.alpineGray],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .shadow(color: isPrimary ? ClioTheme.primaryOrange.opacity(0.4) : Color.black.opacity(0.3), 
                   radius: configuration.isPressed ? 4 : 8, 
                   x: 0, y: configuration.isPressed ? 2 : 4)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func clioCard() -> some View {
        modifier(ClioCardStyle())
    }
    
    func clioButton(isPrimary: Bool = true) -> some View {
        buttonStyle(ClioButtonStyle(isPrimary: isPrimary))
    }
}


