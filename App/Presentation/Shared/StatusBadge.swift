import SwiftUI
import QuoteCore

struct StatusBadge: View {
    let status: QuoteStatus

    var body: some View {
        Text(LocalizedStringKey(labelKey))
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(color)
            .background(color.opacity(0.14), in: Capsule())
            .accessibilityLabel(Text(LocalizedStringKey(labelKey)))
    }

    private var labelKey: String {
        switch status {
        case .draft: return "quote.status.draft"
        case .sent: return "quote.status.sent"
        case .accepted: return "quote.status.accepted"
        case .rejected: return "quote.status.rejected"
        }
    }

    private var color: Color {
        switch status {
        case .draft: return .secondary
        case .sent: return .blue
        case .accepted: return .green
        case .rejected: return .red
        }
    }
}
