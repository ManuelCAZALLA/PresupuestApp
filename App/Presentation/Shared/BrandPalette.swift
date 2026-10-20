import SwiftUI
import UIKit

/// Paleta de las pantallas nuevas (onboarding): fondo suave, tarjetas
/// blancas con borde fino y ámbar solo para avisos. El acento es el del
/// catálogo de recursos, para no duplicarlo.
enum BrandPalette {
    static let background = Color(dynamic: 0xF7F8FA, dark: 0x0E0F12)
    static let card = Color(dynamic: 0xFFFFFF, dark: 0x1B1D21)
    static let border = Color(dynamic: 0xE6E8EC, dark: 0x2E3137)
    static let warning = Color(dynamic: 0xB45309, dark: 0xF0B03A)
    static let accent = Color.accentColor
}

private extension Color {
    /// Color que cambia con el modo claro/oscuro.
    init(dynamic light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}
