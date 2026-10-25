import Foundation

/// Duplica un presupuesto: copia las líneas tal cual (precios del momento),
/// el descuento, las notas, el tipo de IVA por defecto y los datos del
/// cliente; asigna número nuevo, fecha de hoy y estado `draft`.
public final class DuplicateQuote {
    private let quotes: QuoteRepository
    private let profile: ProfileRepository
    private let clock: Clock

    public init(quotes: QuoteRepository, profile: ProfileRepository, clock: Clock) {
        self.quotes = quotes
        self.profile = profile
        self.clock = clock
    }

    public func execute(_ quote: Quote) throws -> Quote {
        let now = clock.now()
        let business = try profile.load()
        let number = CreateQuote.nextNumber(
            existing: try quotes.all(),
            prefix: business?.numberPrefix ?? "P",
            year: Calendar.current.component(.year, from: now)
        )

        let duplicate = Quote(
            id: UUID(),
            number: number,
            date: now,
            validityDays: quote.validityDays,
            client: quote.client,
            status: .draft,
            lines: quote.lines,
            discount: quote.discount,
            notes: quote.notes,
            defaultVATRate: quote.defaultVATRate
        )
        try quotes.save(duplicate)
        return duplicate
    }
}
