import Foundation
import Testing
@testable import PresupuestApp

@Suite("Enlaces de Ajustes")
struct AppLinksTests {
    @Test("La configuración vacía no genera destinos ni enlaces compartidos")
    func emptyConfigurationReturnsNil() {
        let links = AppLinks()

        #expect(links.supportEmail == nil)
        #expect(links.supportMailtoURL(appVersion: "1.0", buildVersion: "1", iosVersion: "17") == nil)
        #expect(links.validWebsiteURL == nil)
        #expect(links.validPrivacyURL == nil)
        #expect(links.validTermsURL == nil)
        #expect(links.reviewURL == nil)
        #expect(links.shareText(appName: "PresupuestApp", phrase: "Presupuesta con tu tarifa") == "PresupuestApp\nPresupuesta con tu tarifa")
    }

    @Test("El mailto codifica el asunto y los datos de versión")
    func supportMailtoEncodesSubjectAndBody() throws {
        let links = AppLinks(supportEmail: "ayuda@example.com")
        let url = try #require(links.supportMailtoURL(
            appVersion: "1.0",
            buildVersion: "7",
            iosVersion: "iOS 17.4"
        ))
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        #expect(components.scheme == "mailto")
        #expect(components.path == "ayuda@example.com")
        #expect(query["subject"] == "Soporte PresupuestApp")
        #expect(query["body"] == "Versión: 1.0\nCompilación: 7\niOS: iOS 17.4")
        #expect(url.absoluteString.contains("%40") == false)
        #expect(url.absoluteString.contains("%0A"))
    }

    @Test("Los enlaces web aceptan HTTP seguro y rechazan otros esquemas")
    func configuredWebURLsAreValidated() {
        let valid = AppLinks(
            websiteURL: URL(string: "https://example.com/site"),
            privacyURL: URL(string: "https://example.com/privacy"),
            termsURL: URL(string: "https://example.com/terms")
        )
        #expect(valid.validWebsiteURL?.absoluteString == "https://example.com/site")
        #expect(valid.validPrivacyURL?.absoluteString == "https://example.com/privacy")
        #expect(valid.validTermsURL?.absoluteString == "https://example.com/terms")

        let invalid = AppLinks(websiteURL: URL(string: "file:///tmp/site"))
        #expect(invalid.validWebsiteURL == nil)
    }

    @Test("La URL de reseña tiene el identificador y la acción de Apple")
    func reviewURLUsesConfiguredID() throws {
        let links = AppLinks(appStoreID: "1234567890")
        let url = try #require(links.reviewURL)
        #expect(url.absoluteString == "https://apps.apple.com/app/id1234567890?action=write-review")

        #expect(AppLinks(appStoreID: "app-id").reviewURL == nil)
    }

    @Test("Compartir añade un enlace solo si hay uno configurado")
    func shareTextUsesConfiguredLink() {
        let withWebsite = AppLinks(websiteURL: URL(string: "https://example.com"))
        #expect(withWebsite.shareText(appName: "PresupuestApp", phrase: "Presupuesta con tu tarifa") == "PresupuestApp\nPresupuesta con tu tarifa\nhttps://example.com")

        let withStoreID = AppLinks(appStoreID: "1234567890")
        #expect(withStoreID.shareText(appName: "PresupuestApp", phrase: "Presupuesta con tu tarifa").hasSuffix("https://apps.apple.com/app/id1234567890?action=write-review"))
    }
}
