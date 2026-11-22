import SwiftUI
import QuoteCore

struct StatusBadge: View {
    let status: QuoteStatus

    var body: some View {
        label
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(color)
            .background(color.opacity(0.14), in: Capsule())
            .accessibilityLabel(label)
    }

    private var label: Text {
        switch status {
        case .draft: Text("quote.status.draft")
        case .sent: Text("quote.status.sent")
        case .accepted: Text("quote.status.accepted")
        case .rejected: Text("quote.status.rejected")
        }
    }

    private var color: Color {
        switch status {
        case .draft: return .secondary
        case .sent: return BrandPalette.accent
        case .accepted: return .green
        case .rejected: return .red
        }
    }
}
