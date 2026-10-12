import Foundation

/// Reloj inyectable: las fechas son una dependencia para tests y cuotas.
public protocol Clock {
    func now() -> Date
}
