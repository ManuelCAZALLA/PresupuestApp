import Foundation
import QuoteCore

/// Traduce errores a claves de texto localizado
/// (ver App/Resources/Localizable.xcstrings).
enum AppErrorMapper {
    static func message(for error: Error) -> String {
        guard let domainError = error as? DomainError else {
            return "error.generic"
        }
        switch domainError {
        case .emptyQuote:
            return "error.emptyQuote"
        case .quotaExceeded:
            return "error.quotaExceeded"
        case .invalidTransition:
            return "error.invalidTransition"
        case .packNotFound:
            return "error.packNotFound"
        }
    }
}
