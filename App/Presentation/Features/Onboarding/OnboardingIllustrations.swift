import SwiftUI

/// Las tres ilustraciones del carrusel, hechas con formas de SwiftUI:
/// sin imágenes externas ni librerías.
enum OnboardingIllustration {
    case tariff
    case estimate
    case send
}

struct OnboardingIllustrationView: View {
    let illustration: OnboardingIllustration

    var body: some View {
        switch illustration {
        case .tariff: TariffIllustration()
        case .estimate: EstimateIllustration()
        case .send: SendIllustration()
        }
    }
}

/// La lista pegada (líneas torcidas) que se convierte en lista limpia.
private struct TariffIllustration: View {
    private let messyWidths: [CGFloat] = [52, 34, 60, 42]
    private let cleanWidths: [CGFloat] = [46, 58, 38, 52]

    var body: some View {
        HStack(spacing: 14) {
            CardSurface(fillsWidth: false, padding: 12) {
                VStack(alignment: .leading, spacing: 9) {
                    ForEach(Array(messyWidths.enumerated()), id: \.offset) { index, width in
                        Line(width: width)
                            .rotationEffect(.degrees(index.isMultiple(of: 2) ? -5 : 4))
                    }
                }
            }

            Image(systemName: "arrow.right")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(BrandPalette.accent)

            CardSurface(fillsWidth: false, padding: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(cleanWidths.enumerated()), id: \.offset) { index, width in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(BrandPalette.accent)
                                .frame(width: 7, height: 7)
                            Line(width: width)
                        }
                    }
                }
            }
        }
    }
}

/// Tres conceptos con su importe y el total destacado.
private struct EstimateIllustration: View {
    private let conceptWidths: [CGFloat] = [62, 76, 50]

    var body: some View {
        CardSurface(fillsWidth: false, padding: 16) {
            VStack(spacing: 12) {
                ForEach(Array(conceptWidths.enumerated()), id: \.offset) { _, width in
                    HStack(spacing: 12) {
                        Line(width: width)
                        Spacer(minLength: 8)
                        Line(width: 24)
                    }
                }

                Divider()

                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(BrandPalette.accent)
                        .frame(width: 42, height: 10)
                    Spacer(minLength: 8)
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(BrandPalette.accent)
                        .frame(width: 40, height: 12)
                }
            }
        }
    }
}

/// La hoja del presupuesto con el icono de compartir.
private struct SendIllustration: View {
    private let lineWidths: [CGFloat] = [92, 70, 88, 62]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            CardSurface(fillsWidth: false, padding: 16) {
                VStack(alignment: .leading, spacing: 11) {
                    Line(width: 60, height: 10, color: BrandPalette.accent)
                    ForEach(Array(lineWidths.enumerated()), id: \.offset) { _, width in
                        Line(width: width)
                    }
                }
            }

            Circle()
                .fill(BrandPalette.accent)
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .offset(x: 12, y: 10)
        }
    }
}

/// Barra neutra que representa una línea de texto.
private struct Line: View {
    var width: CGFloat
    var height: CGFloat = 8
    var color: Color = BrandPalette.border

    var body: some View {
        RoundedRectangle(cornerRadius: height / 2, style: .continuous)
            .fill(color)
            .frame(width: width, height: height)
    }
}
