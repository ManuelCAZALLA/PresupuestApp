import Foundation
import Observation
import QuoteCore

/// Vista modelo de S6 (vista previa y envío del PDF).
@MainActor
@Observable
final class QuotePreviewViewModel {
    enum ViewState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    let quoteID: UUID
    private(set) var state: ViewState = .idle
    private(set) var pdfURL: URL?
    private(set) var quote: Quote?

    private let loadQuote: LoadQuote
    private let exportQuotePDF: ExportQuotePDF
    private let changeQuoteStatus: ChangeQuoteStatus

    init(
        quoteID: UUID,
        loadQuote: LoadQuote,
        exportQuotePDF: ExportQuotePDF,
        changeQuoteStatus: ChangeQuoteStatus
    ) {
        self.quoteID = quoteID
        self.loadQuote = loadQuote
        self.exportQuotePDF = exportQuotePDF
        self.changeQuoteStatus = changeQuoteStatus
    }

    func load() {
        state = .loading
        do {
            let loaded = try loadQuote.execute(id: quoteID)
            quote = loaded
            pdfURL = try exportQuotePDF.execute(loaded)
            state = .loaded
        } catch {
            state = .failed(AppErrorMapper.message(for: error))
        }
    }

    func markSent() {
        guard let quote else { return }
        do {
            self.quote = try changeQuoteStatus.execute(quote, to: .sent)
        } catch {
            state = .failed(AppErrorMapper.message(for: error))
        }
    }
}
