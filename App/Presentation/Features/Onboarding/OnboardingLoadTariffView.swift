import SwiftUI

/// Paso 5: la misma pantalla del catálogo vacío (S7). Cualquiera de las
/// opciones —y "Lo haré luego"— termina el onboarding (D-016).
struct OnboardingLoadTariffView: View {
    let onChoose: (OnboardingViewModel.StartOption) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    Image(systemName: "tag")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(BrandPalette.accent)
                        .accessibilityHidden(true)
                    Text("catalog.empty")
                        .font(.title2.weight(.semibold))
                        .multilineTextAlignment(.center)
                    Text("catalog.empty.message")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityElement(children: .combine)

                TariffStartActions(
                    onImport: { onChoose(.importTariff) },
                    onPaste: { onChoose(.pasteList) },
                    onAddManually: { onChoose(.addManually) }
                )

                Button {
                    onChoose(.later)
                } label: {
                    Text("onboarding.later")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(BrandPalette.accent)
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .containerRelativeFrame(.vertical, alignment: .center)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}
