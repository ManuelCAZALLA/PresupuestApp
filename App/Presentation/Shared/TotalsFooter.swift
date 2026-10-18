import SwiftUI
import QuoteCore

struct TotalsFooter: View {
    let totals: QuoteTotals

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            labeled("quote.totals.subtotal", totals.subtotal)
            if totals.discount > 0 {
                labeled("quote.totals.discount", totals.discount)
            }
            ForEach(Array(totals.vatBreakdown.enumerated()), id: \.offset) { _, group in
                HStack {
                    Text("quote.totals.vat")
                    Text(verbatim: "\(CurrencyFormatter.plainString(from: group.rate)) %")
                    Spacer()
                    Text(CurrencyFormatter.string(from: group.vat))
                        .monospacedDigit()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Divider()
            HStack {
                Text("quote.totals.total")
                    .font(.headline)
                Spacer()
                Text(CurrencyFormatter.string(from: totals.total))
                    .font(.title3.weight(.semibold).monospacedDigit())
            }
            .accessibilityElement(children: .combine)
        }
        .padding(.vertical, 4)
    }

    private func labeled(_ key: LocalizedStringKey, _ amount: Decimal) -> some View {
        HStack {
            Text(key)
            Spacer()
            Text(CurrencyFormatter.string(from: amount))
                .monospacedDigit()
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
}
