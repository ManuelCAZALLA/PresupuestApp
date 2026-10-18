import Foundation
import QuoteCore

/// Reloj del sistema: implementación del puerto `Clock` de QuoteCore.
public struct SystemClock: Clock {
    public func now() -> Date { Date() }
}
