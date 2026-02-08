import SwiftUI

struct ThemeColors {
    // 112 Türkiye Acil Sistem Renkleri - Beyaz ve Kırmızı
    static let primaryRed = Color(red: 0.85, green: 0.1, blue: 0.15) // Kırmızı
    static let primaryRedLight = Color(red: 0.95, green: 0.2, blue: 0.2) // Açık kırmızı
    static let primaryRedDark = Color(red: 0.7, green: 0.05, blue: 0.1) // Koyu kırmızı
    
    static let accentWhite = Color.white
    static let accentWhiteLight = Color(red: 0.98, green: 0.98, blue: 0.98)
    static let accentWhiteDark = Color(red: 0.95, green: 0.95, blue: 0.95)
    
    // Arka plan renkleri - light/dark mode'a göre
    static func backgroundGradient(isDark: Bool) -> [Color] {
        if isDark {
            return [
                Color(red: 0.1, green: 0.05, blue: 0.05),
                Color(red: 0.15, green: 0.08, blue: 0.08)
            ]
        } else {
            return [
                Color(red: 0.98, green: 0.97, blue: 0.97),
                Color(red: 0.95, green: 0.94, blue: 0.94)
            ]
        }
    }
    
    // Kart arka plan renkleri
    static func cardBackground(isDark: Bool) -> [Color] {
        if isDark {
            return [
                Color.white.opacity(0.1),
                Color.white.opacity(0.05)
            ]
        } else {
            return [
                Color.white.opacity(0.9),
                Color.white.opacity(0.8)
            ]
        }
    }
    
    // Kart border renkleri
    static func cardBorder(isDark: Bool) -> [Color] {
        if isDark {
            return [
                Color.white.opacity(0.2),
                Color.white.opacity(0.05)
            ]
        } else {
            return [
                primaryRed.opacity(0.2),
                primaryRed.opacity(0.1)
            ]
        }
    }
    
    // Metin renkleri
    static func primaryText(isDark: Bool) -> Color {
        isDark ? .white : .black
    }
    
    static func secondaryText(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.7) : Color.black.opacity(0.6)
    }
    
    static func tertiaryText(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.5) : Color.black.opacity(0.4)
    }
}
