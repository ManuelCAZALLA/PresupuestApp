import Foundation
import QuoteCore
import SwiftData
import Testing
@testable import PresupuestApp

@Suite("SwiftDataQuoteRepository")
@MainActor
struct SwiftDataQuoteRepositoryTests {
    @Test("Deleting a quote cascades its lines and preserves unrelated records")
    func deletingQuotePreservesCatalogProfileAndOtherQuotes() throws {
        let container = try PersistenceSetup.makeInMemoryModelContainer()
        let quoteRepository = SwiftDataQuoteRepository(container: container)
        let itemRepository = SwiftDataItemRepository(container: container)
        let profileRepository = SwiftDataProfileRepository(container: container)
        let item = Item(name: "Catalog item", unitPrice: Decimal(37), vatRate: Decimal(21))
        let profile = BusinessProfile(name: "Business", numberPrefix: "P")
        try itemRepository.save(item)
        try profileRepository.save(profile)

        func quote(number: String, client: String) -> Quote {
            Quote(
                number: number,
                date: Date(timeIntervalSince1970: 1_700_000_000),
                validityDays: 30,
                client: Client(name: client),
                status: .draft,
                lines: [
                    QuoteLine(
                        itemID: item.id,
                        name: item.name,
                        unit: item.unit,
                        quantity: Decimal(2),
                        unitPrice: item.unitPrice,
                        vatRate: Decimal(21),
                        origin: .manual
                    )
                ],
                discount: .none,
                notes: "",
                defaultVATRate: Decimal(21)
            )
        }

        let quoteToDelete = quote(number: "P-2026-0001", client: "Delete")
        let quoteToKeep = quote(number: "P-2026-0002", client: "Keep")
        try quoteRepository.save(quoteToDelete)
        try quoteRepository.save(quoteToKeep)

        try quoteRepository.delete(id: quoteToDelete.id)

        #expect(try quoteRepository.quote(id: quoteToDelete.id) == nil)
        #expect(try quoteRepository.quote(id: quoteToKeep.id) == quoteToKeep)
        #expect(try itemRepository.item(id: item.id) == item)
        #expect(try profileRepository.load()?.name == profile.name)

        let context = ModelContext(container)
        let remainingLines = try context.fetch(FetchDescriptor<QuoteLineRecord>())
        #expect(remainingLines.count == 1)
        #expect(remainingLines.first?.quote?.id == quoteToKeep.id)
    }
}
