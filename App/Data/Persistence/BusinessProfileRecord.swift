import Foundation
import SwiftData
import QuoteCore

/// Registro del perfil de empresa (configuración única).
@Model
final class BusinessProfileRecord {
    var name: String
    var taxID: String
    var phone: String
    var email: String
    var logo: Data?
    var defaultVATRate: Decimal
    var terms: String
    var validityDays: Int
    var numberPrefix: String

    init(
        name: String,
        taxID: String,
        phone: String,
        email: String,
        logo: Data?,
        defaultVATRate: Decimal,
        terms: String,
        validityDays: Int,
        numberPrefix: String
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

    func toDomain() -> BusinessProfile {
        BusinessProfile(
            name: name,
            taxID: taxID,
            phone: phone,
            email: email,
            logo: logo,
            defaultVATRate: defaultVATRate,
            terms: terms,
            validityDays: validityDays,
            numberPrefix: numberPrefix
        )
    }

    func apply(domain: BusinessProfile) {
        name = domain.name
        taxID = domain.taxID
        phone = domain.phone
        email = domain.email
        logo = domain.logo
        defaultVATRate = domain.defaultVATRate
        terms = domain.terms
        validityDays = domain.validityDays
        numberPrefix = domain.numberPrefix
    }
}

extension BusinessProfileRecord {
    convenience init(domain: BusinessProfile) {
        self.init(
            name: domain.name,
            taxID: domain.taxID,
            phone: domain.phone,
            email: domain.email,
            logo: domain.logo,
            defaultVATRate: domain.defaultVATRate,
            terms: domain.terms,
            validityDays: domain.validityDays,
            numberPrefix: domain.numberPrefix
        )
    }
}
