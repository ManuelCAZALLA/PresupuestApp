import SwiftUI

/// Control +/− pensado para usarse en obra, con una mano (zona táctil ≥ 44 pt).
struct QuantityStepper: View {
    let valueLabel: String
    let accessibilityValue: String
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Button(action: onDecrease) {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel("quote.line.decrease")

            Text(valueLabel)
                .font(.body.monospacedDigit())
                .frame(minWidth: 36)
                .accessibilityHidden(true)

            Button(action: onIncrease) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel("quote.line.increase")
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityValue(accessibilityValue)
    }
}
