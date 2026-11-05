import Foundation
import Testing
@testable import QuoteCore

@Suite("Modo sugerencia del parser")
struct ParserSuggestionModeTests {
    @Test func defaultMatcherAlwaysPreselectsBestSuggestionWithoutAuto() {
        let likely = item(name: "alpha item", id: "00000000-0000-0000-0000-000000000002")
        let other = item(name: "unrelated", id: "00000000-0000-0000-0000-000000000001")

        let line = Matcher().match(
            remainingText: "alpha",
            quantity: 1,
            quantityWasAssumed: true,
            spokenUnit: nil,
            catalog: [other, likely]
        )

        #expect(line.status == .ambiguous)
        #expect(line.candidates.first?.item.id == likely.id)
    }

    private func item(name: String, id: String) -> Item {
        Item(id: UUID(uuidString: id)!, name: name, aliases: [], unit: .unit, unitPrice: 0, kind: .other, category: nil)
    }
}
