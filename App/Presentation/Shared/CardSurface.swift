import SwiftUI

/// Tarjeta con estilo moderno (Liquid Glass cuando esté disponible).
struct CardSurface<Content: View>: View {
    var fillsWidth = true
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            content
                .padding(padding)
                .frame(maxWidth: fillsWidth ? .infinity : nil, alignment: .leading)
                .glassEffect(.regular.interactive(), in: shape)
        } else {
            content
                .padding(padding)
                .frame(maxWidth: fillsWidth ? .infinity : nil, alignment: .leading)
                .background(.ultraThinMaterial, in: shape)
                .overlay(shape.strokeBorder(.quaternary.opacity(0.5), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.02), radius: 10, y: 4)
        }
    }
}
