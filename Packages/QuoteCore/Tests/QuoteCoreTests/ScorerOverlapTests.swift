import Foundation
import Testing
@testable import QuoteCore

@Suite("Solapamiento léxico general del scorer")
struct ScorerOverlapTests {
    @Test func unrelatedCatalogItemHasNoSharedWordsOrNumbers() {
        let item = makeItem(name: "alfa beta", aliases: ["gamma delta"])
        #expect(!Scorer().sharesWordOrNumber(segment: "epsilon zeta 17", item: item))
    }

    @Test func sharedNumberCountsAsOverlap() {
        let item = makeItem(name: "alfa beta 17", aliases: [])
        #expect(Scorer().sharesWordOrNumber(segment: "epsilon 17", item: item))
    }

    @Test func catalogAliasCountsAsOverlap() {
        let item = makeItem(name: "alfa beta", aliases: ["gamma delta"])
        #expect(Scorer().sharesWordOrNumber(segment: "epsilon gamma", item: item))
    }

    private func makeItem(name: String, aliases: [String]) -> Item {
        Item(id: UUID(), name: name, aliases: aliases, unit: .unit, unitPrice: 0, kind: .other, category: nil)
    }
}
