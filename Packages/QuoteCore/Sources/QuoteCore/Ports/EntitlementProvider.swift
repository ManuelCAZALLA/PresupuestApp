import Foundation

/// Plan del usuario. El plan lo decide `EntitlementProvider` (puerto).
public enum Plan: Equatable, Sendable {
    case free
    case pro
}

/// Puerto de entitlements: decide el plan actual.
public protocol EntitlementProvider {
    func currentPlan() -> Plan
}
