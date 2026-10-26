import SwiftUI

/// HomeLife tema ve renk paleti
public struct AppTheme {
    // Ana renkler
    public static let primary = Color(hex: "#4F46E5")     // Indigo
    public static let primaryLight = Color(hex: "#818CF8")
    public static let secondary = Color(hex: "#06B6D4")   // Cyan
    public static let success = Color(hex: "#10B981")     // Emerald
    public static let warning = Color(hex: "#F59E0B")     // Amber
    public static let danger = Color(hex: "#EF4444")      // Red
    
    // Zemin ve Kart Renkleri
    public static let background = Color(uiColor: .systemGroupedBackground)
    public static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    public static let textPrimary = Color.primary
    public static let textSecondary = Color.secondary
    
    // Gradientler
    public static let primaryGradient = LinearGradient(
        colors: [Color(hex: "#4F46E5"), Color(hex: "#7C3AED")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let warmGradient = LinearGradient(
        colors: [Color(hex: "#F59E0B"), Color(hex: "#EF4444")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let mintGradient = LinearGradient(
        colors: [Color(hex: "#10B981"), Color(hex: "#06B6D4")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
