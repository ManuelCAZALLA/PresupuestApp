import Foundation
import Testing
@testable import QuoteCore

@Suite("Extracción general de cantidad y medida")
struct QuantityExtractorGeneralRuleTests {
    @Test func numberAtStartIsQuantity() {
        let result = QuantityExtractor().extract(from: "9 generic item")
        #expect(result.quantity == 9)
        #expect(!result.quantityWasAssumed)
        #expect(result.remainingText == "generic item")
    }

    @Test func numberWithoutUnitAfterWordsRemainsSpecification() {
        let result = QuantityExtractor().extract(from: "generic item 9")
        #expect(result.quantity == 1)
        #expect(result.quantityWasAssumed)
        #expect(result.remainingText == "generic item 9")
    }

    @Test func numberFollowedByKnownUnitIsQuantity() {
        let result = QuantityExtractor().extract(from: "generic item 9 metros")
        #expect(result.quantity == 9)
        #expect(!result.quantityWasAssumed)
        #expect(result.spokenUnit == .meter)
        #expect(result.remainingText == "generic item")
    }

    @Test func leadingQuantityLeavesLaterNumberAsSpecification() {
        let result = QuantityExtractor().extract(from: "1 generic item 9")
        #expect(result.quantity == 1)
        #expect(result.remainingText == "generic item 9")
    }

    @Test func literUnitIsRecognizedWithoutInventingMeasureKind() {
        let result = QuantityExtractor().extract(from: "generic item 23 litros")
        #expect(result.quantity == 23)
        #expect(!result.quantityWasAssumed)
        #expect(result.spokenUnit == nil)
        #expect(result.remainingText == "generic item")
    }
}
