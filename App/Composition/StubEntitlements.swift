import Foundation
import QuoteCore

/// Entitlements provisionales: la v1 se publica sin límite de presupuestos.
/// El puerto ya vive en QuoteCore; M7 sustituirá esto por StoreKit.
struct StubEntitlements: EntitlementProvider {
    let plan: Plan

    init(plan: Plan = .pro) {
        self.plan = plan
    }

    func currentPlan() -> Plan { plan }
}
