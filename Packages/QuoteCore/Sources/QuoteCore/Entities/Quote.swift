import Foundation

/// Presupuesto. Las líneas son copias de las partidas en el momento de crear la línea.
/// App multisector: no hay `trade`. El PDF por defecto no muestra importes por línea.
public struct Quote: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var number: String
    public var date: Date
    public var issueDate: Date
    public var validityDays: Int
    public var client: Client
    public var status: QuoteStatus
    public var lines: [QuoteLine]
    public var discount: Discount
    public var notes: String
    public var defaultVATRate: Decimal
    /// Datos profesionales del presupuesto.
    public var title: String
    public var workDescription: String
    public var scopeOfWork: String
    public var exclusions: String
    public var paymentTerms: String
    /// Override por presupuesto: `nil` = usar el ajuste global del perfil.
    public var showLineAmounts: Bool?
    public var shareMessage: String

    public init(
        id: UUID = UUID(),
        number: String,
        date: Date,
        issueDate: Date? = nil,
        validityDays: Int,
        client: Client,
        status: QuoteStatus,
        lines: [QuoteLine],
        discount: Discount,
        notes: String,
        defaultVATRate: Decimal,
        title: String = "",
        workDescription: String = "",
        scopeOfWork: String = "",
        exclusions: String = "",
        paymentTerms: String = "",
        showLineAmounts: Bool? = nil,
        shareMessage: String = Quote.defaultShareMessage
    ) {
        self.id = id
        self.number = number
        self.date = date
        self.issueDate = issueDate ?? date
        self.validityDays = validityDays
        self.client = client
        self.status = status
        self.lines = lines
        self.discount = discount
        self.notes = notes
        self.defaultVATRate = defaultVATRate
        self.title = title
        self.workDescription = workDescription
        self.scopeOfWork = scopeOfWork
        self.exclusions = exclusions
        self.paymentTerms = paymentTerms
        self.showLineAmounts = showLineAmounts
        self.shareMessage = shareMessage
    }

    /// Plantilla por defecto para compartir el presupuesto.
    public static let defaultShareMessage =
        "Hola {cliente}, te paso el presupuesto de {título} (ref. {número}). Cualquier duda, me dices."

    /// Mensaje interpolado con cliente, título y número.
    public func shareMessage(for clientName: String) -> String {
        shareMessage
            .replacingOccurrences(of: "{cliente}", with: clientName)
            .replacingOccurrences(of: "{título}", with: title.isEmpty ? number : title)
            .replacingOccurrences(of: "{numero}", with: number)
            .replacingOccurrences(of: "{número}", with: number)
    }
}
