import Foundation

public struct DownPaymentResult: Equatable, Sendable {
    public let percent: Decimal
    public let amount: Decimal
    public let remainder: Decimal

    public init(percent: Decimal, amount: Decimal, remainder: Decimal) {
        self.percent = percent
        self.amount = amount
        self.remainder = remainder
    }
}

public final class CalculateDownPayment {
    public init() {}

    public func execute(totalWithVAT: Decimal, percent: Decimal) -> DownPaymentResult {
        let p = max(Decimal(0), percent)
        let amount = RoundingPolicy.round2(totalWithVAT * p / Decimal(100))
        let remainder = RoundingPolicy.round2(totalWithVAT - amount)
        return DownPaymentResult(percent: p, amount: amount, remainder: remainder)
    }
}
