import Foundation
import SwiftData
import QuoteCore

/// Repositorio de presupuestos sobre SwiftData.
public struct SwiftDataQuoteRepository: QuoteRepository {
    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func all() throws -> [Quote] {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<QuoteRecord>())
        return records.map { $0.toDomain() }
    }

    public func quote(id: UUID) throws -> Quote? {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<QuoteRecord>(predicate: #Predicate { $0.id == id })
        guard let record = try context.fetch(descriptor).first else { return nil }
        return record.toDomain()
    }

    public func save(_ quote: Quote) throws {
        let context = ModelContext(container)
        let id = quote.id
        let descriptor = FetchDescriptor<QuoteRecord>(predicate: #Predicate { $0.id == id })
        if let existing = try context.fetch(descriptor).first {
            apply(domain: quote, to: existing, in: context)
        } else {
            context.insert(QuoteRecord(domain: quote))
        }
        try context.save()
    }

    public func delete(id: UUID) throws {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<QuoteRecord>(predicate: #Predicate { $0.id == id })
        guard let record = try context.fetch(descriptor).first else { return }
        context.delete(record)
        try context.save()
    }

    private func apply(domain: Quote, to record: QuoteRecord, in context: ModelContext) {
        record.number = domain.number
        record.date = domain.date
        record.validityDays = domain.validityDays
        record.clientName = domain.client.name
        record.clientPhone = domain.client.phone
        record.clientAddress = domain.client.address
        record.clientWorkAddress = domain.client.workAddress
        record.statusRaw = domain.status.rawValue
        record.notes = domain.notes
        record.defaultVATRate = domain.defaultVATRate
        switch domain.discount {
        case .none:
            record.discountKindRaw = "none"
            record.discountValue = Decimal(0)
        case .percent(let p):
            record.discountKindRaw = "percent"
            record.discountValue = p
        case .amount(let a):
            record.discountKindRaw = "amount"
            record.discountValue = a
        }
        for line in record.lines {
            context.delete(line)
        }
        for line in domain.lines {
            let lineRecord = QuoteLineRecord(domain: line)
            lineRecord.quote = record
            context.insert(lineRecord)
        }
    }
}
