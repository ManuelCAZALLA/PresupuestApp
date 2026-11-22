import Foundation
import QuoteCore

/// Traduce errores del dominio a texto localizado.
enum AppErrorMapper {
    static func message(for error: Error) -> String {
        guard let domainError = error as? DomainError else {
            return String(localized: "error.generic")
        }
        switch domainError {
        case .emptyQuote:
            return String(localized: "error.emptyQuote")
        case .quotaExceeded:
            return String(localized: "error.quotaExceeded")
        case .invalidTransition:
            return String(localized: "error.invalidTransition")
        case .importFailed:
            return String(localized: "error.importFailed")
        case .quoteNotFound:
            return String(localized: "error.quoteNotFound")
        case .lineNotFound:
            return String(localized: "error.lineNotFound")
        case .itemNotFound:
            return String(localized: "error.itemNotFound")
        case .kitNotFound:
            return String(localized: "error.kitNotFound")
        }
    }
}
