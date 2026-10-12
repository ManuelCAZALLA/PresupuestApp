import Foundation

/// Crea un presupuesto vacío en borrador, con numeración
/// `<prefijo>-<año>-<secuencia de 4 dígitos>` (reinicia cada año) y
/// cuota gratuita de 5 presupuestos por mes natural.
public final class CreateQuote {
    private let quotes: QuoteRepository
    private let profile: ProfileRepository
    private let clock: Clock
    private let entitlements: EntitlementProvider

    public init(
        quotes: QuoteRepository,
        profile: ProfileRepository,
        clock: Clock,
        entitlements: EntitlementProvider
    ) {
        self.quotes = quotes
        self.profile = profile
        self.clock = clock
        self.entitlements = entitlements
    }

    public func execute(client: Client) throws -> Quote {
        let now = clock.now()

        // Cuota: 5 por mes natural en el plan gratuito.
        if entitlements.currentPlan() == .free {
            let used = QuotaPolicy.quotesCreated(inMonthOf: now, quotes: try quotes.all())
            if used >= QuotaPolicy.freeMonthlyLimit {
                throw DomainError.quotaExceeded
            }
        }

        let business = try profile.load()
        let number = CreateQuote.nextNumber(
            existing: try quotes.all(),
            prefix: business?.numberPrefix ?? "P",
            year: Calendar.current.component(.year, from: now)
        )

        let quote = Quote(
            id: UUID(),
            number: number,
            date: now,
            validityDays: business?.validityDays ?? 30,
            client: client,
            status: .draft,
            lines: [],
            discount: .none,
            notes: "",
            defaultVATRate: business?.defaultVATRate ?? Decimal(21)
        )
        try quotes.save(quote)
        return quote
    }

    /// Siguiente número de la secuencia anual: `<prefijo>-<año>-<secuencia>`.
    static func nextNumber(existing: [Quote], prefix: String, year: Int) -> String {
        let marker = "\(prefix)-\(year)-"
        var maxSequence = 0
        for quote in existing {
            guard quote.number.hasPrefix(marker),
                  let sequence = Int(quote.number.dropFirst(marker.count)) else { continue }
            maxSequence = max(maxSequence, sequence)
        }
        return String(format: "%@-%d-%04d", prefix, year, maxSequence + 1)
    }
}
