import Foundation

/// Presupuesto. Las líneas son copias de las partidas en el momento de crear la línea.
public struct Quote: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var number: String
    public var date: Date
    public var validityDays: Int
    public var client: Client
    public var status: QuoteStatus
    public var lines: [QuoteLine]
    public var discount: Discount
    public var notes: String
    public var defaultVATRate: Decimal

    public init(
        id: UUID,
        number: String,
        date: Date,
        validityDays: Int,
        client: Client,
        status: QuoteStatus,
        lines: [QuoteLine],
        discount: Discount,
        notes: String,
        defaultVATRate: Decimal
    ) {
        self.id = id
        self.number = number
        self.date = date
        self.validityDays = validityDays
        self.client = client
        self.status = status
        self.lines = lines
        self.discount = discount
        self.notes = notes
        self.defaultVATRate = defaultVATRate
    }
}
