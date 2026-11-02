import Testing
import Foundation
@testable import QuoteCore

struct DownPaymentTests {
    @Test func vectors() {
        let calc = CalculateDownPayment()
        let total = Decimal(string: "1004.30")!
        // 30 % of 1.004,30 → 301,29 and 703,01
        let r30 = calc.execute(totalWithVAT: total, percent: Decimal(30))
        #expect(r30.amount == RoundingPolicy.round2(total * Decimal(30) / Decimal(100)))
        #expect(r30.remainder == RoundingPolicy.round2(total - r30.amount))
        #expect(r30.amount == Decimal(string: "301.29")!)
        #expect(r30.remainder == Decimal(string: "703.01")!)
        // 12,5 % of 1.004,30 → 125,54 and 878,76
        let r125 = calc.execute(totalWithVAT: total, percent: Decimal(string: "12.5")!)
        #expect(r125.amount == Decimal(string: "125.54")!)
        #expect(r125.remainder == Decimal(string: "878.76")!)
    }
}
