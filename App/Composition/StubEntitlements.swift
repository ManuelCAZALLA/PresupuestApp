import Foundation
import QuoteCore

/// Entitlements provisionales: plan gratuito hasta el hito M7 (Paywall).
/// El puerto ya vive en QuoteCore; M7 sustituirá esto por StoreKit.
struct StubEntitlements: EntitlementProvider {
    let plan: Plan

    init(plan: Plan = .free) {
        self.plan = plan
    }

    func currentPlan() -> Plan { plan }
}
