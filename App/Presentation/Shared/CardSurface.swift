import SwiftUI

/// Tarjeta blanca con borde fino: el contenedor de las pantallas nuevas.
struct CardSurface<Content: View>: View {
    var fillsWidth = true
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: fillsWidth ? .infinity : nil, alignment: .leading)
            .background(BrandPalette.card, in: shape)
            .overlay(shape.strokeBorder(BrandPalette.border, lineWidth: 1))
    }
}
