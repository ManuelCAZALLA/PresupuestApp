import Foundation

/// Datos de empresa: cabecera de los presupuestos y valores por defecto.
public struct BusinessProfile: Equatable, Sendable {
    public var name: String
    public var taxID: String
    public var phone: String
    public var email: String
    public var logo: Data?
    public var defaultVATRate: Decimal
    public var terms: String
    public var validityDays: Int
    public var numberPrefix: String

    public init(
        name: String = "",
        taxID: String = "",
        phone: String = "",
        email: String = "",
        logo: Data? = nil,
        defaultVATRate: Decimal = Decimal(0),
        terms: String = "",
        validityDays: Int = 30,
        numberPrefix: String = "P"
    ) {
        self.name = name
        self.taxID = taxID
        self.phone = phone
        self.email = email
        self.logo = logo
        self.defaultVATRate = defaultVATRate
        self.terms = terms
        self.validityDays = validityDays
        self.numberPrefix = numberPrefix
    }
}
