import SwiftUI

// MARK: - Colors

enum VTColors {
    static let background = Color(hex: 0x1A1A1A)
    static let surface = Color(hex: 0x2A2A2A)
    static let textPrimary = Color(hex: 0xF5F5F5)
    static let textMuted = Color(hex: 0x8A8A8A)
    static let accent = Color(hex: 0x4A9EFF)
    static let recording = Color(hex: 0xFF3B30)
    static let success = Color(hex: 0x34C759)
}

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Spacing

enum VTSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

// MARK: - Typography

enum VTFont {
    static func title() -> Font { .system(size: 16, weight: .semibold, design: .default) }
    static func body() -> Font { .system(size: 13, weight: .regular, design: .default) }
    static func caption() -> Font { .system(size: 11, weight: .regular, design: .default) }
    static func mono() -> Font { .system(size: 12, weight: .regular, design: .monospaced) }
}

// MARK: - View Modifiers

struct VTCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(VTSpacing.md)
            .background(VTColors.surface)
            .cornerRadius(8)
    }
}

extension View {
    func vtCard() -> some View {
        modifier(VTCardStyle())
    }
}
