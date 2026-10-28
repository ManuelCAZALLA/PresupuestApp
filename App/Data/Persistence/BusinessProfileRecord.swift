import Foundation
import SwiftData
import QuoteCore

/// Registro del perfil de empresa (configuración única).
/// Esquema v3: dirección, IBAN opcional, textos por defecto,
/// y ajuste global para el PDF.
@Model
final class BusinessProfileRecord {
    var name: String
    var address: String
    var taxID: String
    var phone: String
    var email: String
    var iban: String?
    var logo: Data?
    var defaultVATRate: Decimal
    var terms: String
    var paymentTermsDefault: String
    var scopeOfWorkDefault: String
    var exclusionsDefault: String
    var validityDays: Int
    var numberPrefix: String
    var showLineAmountsInPDF: Bool

    init(
        name: String,
        address: String = "",
        taxID: String,
        phone: String,
        email: String,
        iban: String? = nil,
        logo: Data?,
        defaultVATRate: Decimal,
        terms: String,
        paymentTermsDefault: String = "",
        scopeOfWorkDefault: String = "",
        exclusionsDefault: String = "",
        validityDays: Int,
        numberPrefix: String,
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

    func toDomain() -> BusinessProfile {
        BusinessProfile(
            name: name,
            address: address,
            taxID: taxID,
            phone: phone,
            email: email,
            iban: iban,
            logo: logo,
            defaultVATRate: defaultVATRate,
            terms: terms,
            paymentTermsDefault: paymentTermsDefault,
            scopeOfWorkDefault: scopeOfWorkDefault,
            exclusionsDefault: exclusionsDefault,
            validityDays: validityDays,
            numberPrefix: numberPrefix,
            showLineAmountsInPDF: showLineAmountsInPDF
        )
    }

    func apply(domain: BusinessProfile) {
        name = domain.name
        address = domain.address
        taxID = domain.taxID
        phone = domain.phone
        email = domain.email
        iban = domain.iban
        logo = domain.logo
        defaultVATRate = domain.defaultVATRate
        terms = domain.terms
        paymentTermsDefault = domain.paymentTermsDefault
        scopeOfWorkDefault = domain.scopeOfWorkDefault
        exclusionsDefault = domain.exclusionsDefault
        validityDays = domain.validityDays
        numberPrefix = domain.numberPrefix
        showLineAmountsInPDF = domain.showLineAmountsInPDF
    }
}

extension BusinessProfileRecord {
    convenience init(domain: BusinessProfile) {
        self.init(
            name: domain.name,
            address: domain.address,
            taxID: domain.taxID,
            phone: domain.phone,
            email: domain.email,
            iban: domain.iban,
            logo: domain.logo,
            defaultVATRate: domain.defaultVATRate,
            terms: domain.terms,
            paymentTermsDefault: domain.paymentTermsDefault,
            scopeOfWorkDefault: domain.scopeOfWorkDefault,
            exclusionsDefault: domain.exclusionsDefault,
            validityDays: domain.validityDays,
            numberPrefix: domain.numberPrefix,
            showLineAmountsInPDF: domain.showLineAmountsInPDF
        )
    }
}
