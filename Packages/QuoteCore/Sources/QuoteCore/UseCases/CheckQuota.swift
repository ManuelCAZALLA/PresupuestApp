import Foundation

/// Estado de la cuota de presupuestos del mes natural actual.
public struct QuotaStatus: Equatable, Sendable {
    public let plan: Plan
    public let used: Int
    public let limit: Int?
    public let remaining: Int
    public let canCreate: Bool

    public init(plan: Plan, used: Int, limit: Int?, remaining: Int, canCreate: Bool) {
        self.plan = plan
        self.used = used
        self.limit = limit
        self.remaining = remaining
        self.canCreate = canCreate
    }
}

/// Comprueba la cuota del mes natural actual. Plan gratuito: 5 por mes;
/// Plan Pro: sin límite (`limit` nulo).
public final class CheckQuota {
    private let quotes: QuoteRepository
    private let clock: Clock
    private let entitlements: EntitlementProvider

    public init(quotes: QuoteRepository, clock: Clock, entitlements: EntitlementProvider) {
        self.quotes = quotes
        self.clock = clock
        self.entitlements = entitlements
    }

    public func execute() throws -> QuotaStatus {
        let plan = entitlements.currentPlan()
        let used = QuotaPolicy.quotesCreated(inMonthOf: clock.now(), quotes: try quotes.all())
        let limit: Int? = plan == .free ? QuotaPolicy.freeMonthlyLimit : nil
        let remaining = limit.map { max($0 - used, 0) } ?? 0
        let canCreate: Bool
        switch limit {
        case .some:
            canCreate = remaining > 0
        case .none:
            canCreate = true
        }
        return QuotaStatus(plan: plan, used: used, limit: limit, remaining: remaining, canCreate: canCreate)
    }
}
