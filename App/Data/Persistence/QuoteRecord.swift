import Foundation
import SwiftData
import QuoteCore

/// Registro de presupuesto. Las líneas guardan COPIA de nombre,
/// unidad y precio del momento (snapshot, nunca referencia viva).
@Model
final class QuoteRecord {
    @Attribute(.unique) var id: UUID
    var number: String
    var date: Date
    var validityDays: Int
    var clientName: String
    var clientPhone: String
    var clientAddress: String
    var clientWorkAddress: String?
    var statusRaw: String
    var discountKindRaw: String
    var discountValue: Decimal
    var notes: String
    var defaultVATRate: Decimal
    @Relationship(deleteRule: .cascade) var lines: [QuoteLineRecord]

    init(
        id: UUID,
        number: String,
        date: Date,
        validityDays: Int,
        clientName: String,
        clientPhone: String,
        clientAddress: String,
        clientWorkAddress: String?,
        statusRaw: String,
        discountKindRaw: String,
        discountValue: Decimal,
        notes: String,
        defaultVATRate: Decimal,
        lines: [QuoteLineRecord]
    ) {
        self.id = id
        self.number = number
        self.date = date
        self.validityDays = validityDays
        self.clientName = clientName
        self.clientPhone = clientPhone
        self.clientAddress = clientAddress
        self.clientWorkAddress = clientWorkAddress
        self.statusRaw = statusRaw
        self.discountKindRaw = discountKindRaw
        self.discountValue = discountValue
        self.notes = notes
        self.defaultVATRate = defaultVATRate
        self.lines = lines
    }

    func toDomain() -> Quote {
        let discount: Discount
        switch discountKindRaw {
        case "percent": discount = .percent(discountValue)
        case "amount": discount = .amount(discountValue)
        default: discount = .none
        }
        return Quote(
            id: id,
            number: number,
            date: date,
            validityDays: validityDays,
            client: Client(
                name: clientName,
                phone: clientPhone,
                address: clientAddress,
                workAddress: clientWorkAddress
            ),
            status: QuoteStatus(rawValue: statusRaw) ?? .draft,
            lines: lines.map { $0.toDomain() },
            discount: discount,
            notes: notes,
            defaultVATRate: defaultVATRate
        )
    }
}

extension QuoteRecord {
    convenience init(domain: Quote) {
        let discountKind: String
        let discountValue: Decimal
        switch domain.discount {
        case .percent(let p):
            discountKind = "percent"
            discountValue = p
        case .amount(let a):
            discountKind = "amount"
            discountValue = a
        case .none:
            discountKind = "none"
            discountValue = Decimal(0)
        }
        self.init(
            id: domain.id,
            number: domain.number,
            date: domain.date,
            validityDays: domain.validityDays,
            clientName: domain.client.name,
            clientPhone: domain.client.phone,
            clientAddress: domain.client.address,
            clientWorkAddress: domain.client.workAddress,
            statusRaw: domain.status.rawValue,
            discountKindRaw: discountKind,
            discountValue: discountValue,
            notes: domain.notes,
            defaultVATRate: domain.defaultVATRate,
            lines: domain.lines.map { QuoteLineRecord(domain: $0) }
        )
    }
}

@Model
final class QuoteLineRecord {
    @Attribute(.unique) var id: UUID
    var itemID: UUID?
    var name: String
    var unitRaw: String
    var quantity: Decimal
    var unitPrice: Decimal
    var vatRate: Decimal
    var originRaw: String
    @Relationship var quote: QuoteRecord?

    init(
        id: UUID,
        itemID: UUID?,
        name: String,
        unitRaw: String,
        quantity: Decimal,
        unitPrice: Decimal,
        vatRate: Decimal,
        originRaw: String,
        quote: QuoteRecord? = nil
    ) {
        self.id = id
        self.itemID = itemID
        self.name = name
        self.unitRaw = unitRaw
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.vatRate = vatRate
        self.originRaw = originRaw
        self.quote = quote
    }

    func toDomain() -> QuoteLine {
        QuoteLine(
            id: id,
            itemID: itemID,
            name: name,
            unit: MeasureUnit(rawValue: unitRaw) ?? .unit,
            quantity: quantity,
            unitPrice: unitPrice,
            vatRate: vatRate,
            origin: QuoteLine.Origin(rawValue: originRaw) ?? .manual
        )
    }
}

extension QuoteLineRecord {
    convenience init(domain: QuoteLine) {
        self.init(
            id: domain.id,
            itemID: domain.itemID,
            name: domain.name,
            unitRaw: domain.unit.rawValue,
            quantity: domain.quantity,
            unitPrice: domain.unitPrice,
            vatRate: domain.vatRate,
            originRaw: domain.origin.rawValue
        )
    }
}
