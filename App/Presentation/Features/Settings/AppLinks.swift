import Foundation

struct AppLinks: Equatable {
    let supportEmail: String?
    let websiteURL: URL?
    let privacyURL: URL?
    let termsURL: URL?
    let appStoreID: String?

    init(
        supportEmail: String? = nil,
        websiteURL: URL? = nil,
        privacyURL: URL? = nil,
        termsURL: URL? = nil,
        appStoreID: String? = nil
    ) {
        self.supportEmail = supportEmail
        self.websiteURL = websiteURL
        self.privacyURL = privacyURL
        self.termsURL = termsURL
        self.appStoreID = appStoreID
    }

    static let configured = AppLinks(
        supportEmail: "soporte@presupuestapp.example",
        websiteURL: URL(string: "https://example.com/presupuestapp"),
        privacyURL: URL(string: "https://manuelcazalla.github.io/PresupuestApp-Politica-Privacidad.html/"),
        termsURL: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"),
        appStoreID: "0000000000"
    )

    func supportMailtoURL(
        appVersion: String,
        buildVersion: String,
        iosVersion: String
    ) -> URL? {
        guard let email = supportEmail?.trimmingCharacters(in: .whitespacesAndNewlines),
              Self.isValidEmailAddress(email)
        else { return nil }

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email
        components.queryItems = [
            URLQueryItem(name: "subject", value: String(localized: "settings.support.mail.subject")),
            URLQueryItem(
                name: "body",
                value: String.localizedStringWithFormat(
                    String(localized: "settings.support.mail.body"),
                    appVersion,
                    buildVersion,
                    iosVersion
                )
            )
        ]
        return components.url
    }

    var validWebsiteURL: URL? { Self.validWebURL(websiteURL) }
    var validPrivacyURL: URL? { Self.validWebURL(privacyURL) }
    var validTermsURL: URL? { Self.validWebURL(termsURL) }

    var reviewURL: URL? {
        guard let appStoreID = appStoreID?.trimmingCharacters(in: .whitespacesAndNewlines),
              !appStoreID.isEmpty,
              appStoreID.allSatisfy(\.isNumber)
        else { return nil }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "apps.apple.com"
        components.path = "/app/id\(appStoreID)"
        components.queryItems = [URLQueryItem(name: "action", value: "write-review")]
        return components.url
    }

    func shareText(appName: String, phrase: String) -> String {
        let message = "\(appName)\n\(phrase)"
        guard let shareURL = validWebsiteURL ?? reviewURL else { return message }
        return "\(message)\n\(shareURL.absoluteString)"
    }

    private static func validWebURL(_ url: URL?) -> URL? {
        guard let url,
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              let host = url.host,
              !host.isEmpty
        else { return nil }
        return url
    }

    private static func isValidEmailAddress(_ address: String) -> Bool {
        guard !address.contains(where: { $0.isWhitespace }) else { return false }
        let parts = address.split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == 2 && !parts[0].isEmpty && parts[1].contains(".")
    }
}
