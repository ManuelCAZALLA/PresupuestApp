import Foundation

/// Datos de empresa: cabecera de los presupuestos y valores por defecto.
/// El IBAN es opcional, solo local, nunca en logs ni en tests
/// (ver docs/DECISIONS.md, D-019).
public struct BusinessProfile: Equatable, Sendable {
    public var name: String
    public var address: String
    public var taxID: String
    public var phone: String
    public var email: String
    public var iban: String?
    public var logo: Data?
    public var defaultVATRate: Decimal
    public var terms: String
    /// Textos por defecto que se copian a los presupuestos nuevos.
    public var paymentTermsDefault: String
    public var scopeOfWorkDefault: String
    public var exclusionsDefault: String
    public var validityDays: Int
    public var numberPrefix: String
    /// Ajuste global: por defecto el PDF no muestra importes por línea.
    public var showLineAmountsInPDF: Bool

    public init(
        name: String = "",
        address: String = "",
        taxID: String = "",
        phone: String = "",
        email: String = "",
        iban: String? = nil,
        logo: Data? = nil,
        defaultVATRate: Decimal = Decimal(0),
        terms: String = "",
        paymentTermsDefault: String = "",
        scopeOfWorkDefault: String = "",
        exclusionsDefault: String = "",
        validityDays: Int = 30,
        numberPrefix: String = "P",
        showLineAmountsInPDF: Bool = false
    ) {
        self.name = name
        self.address = address
        self.taxID = taxID
        self.phone = phone
        self.email = email
        self.iban = iban
        self.logo = logo
        self.defaultVATRate = defaultVATRate
        self.terms = terms
        self.paymentTermsDefault = paymentTermsDefault
        self.scopeOfWorkDefault = scopeOfWorkDefault
        self.exclusionsDefault = exclusionsDefault
        self.validityDays = validityDays
        self.numberPrefix = numberPrefix
        self.showLineAmountsInPDF = showLineAmountsInPDF
    }
}
