import Foundation
import Observation
import QuoteCore

/// Vista modelo de S10 (Ajustes): datos de empresa, IVA por
/// defecto, condiciones, validez y numeración.
@MainActor
@Observable
final class SettingsViewModel {
    enum ViewState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var state: ViewState = .idle
    private(set) var profile = BusinessProfile()
    private(set) var saved = false

    private let loadBusinessProfile: LoadBusinessProfile
    private let saveBusinessProfile: SaveBusinessProfile

    init(
        loadBusinessProfile: LoadBusinessProfile,
        saveBusinessProfile: SaveBusinessProfile
    ) {
        self.loadBusinessProfile = loadBusinessProfile
        self.saveBusinessProfile = saveBusinessProfile
    }

    func load() {
        state = .loading
        do {
            profile = try loadBusinessProfile.execute() ?? BusinessProfile()
            state = .loaded
        } catch {
            state = .failed(AppErrorMapper.message(for: error))
        }
    }

    func update(
        name: String,
        taxID: String,
        phone: String,
        email: String,
        defaultVATRate: Decimal,
        terms: String,
        validityDays: Int,
        numberPrefix: String
    ) {
        profile.name = name
        profile.taxID = taxID
        profile.phone = phone
        profile.email = email
        profile.defaultVATRate = defaultVATRate
        profile.terms = terms
        profile.validityDays = validityDays
        profile.numberPrefix = numberPrefix
        saved = false
    }

    func setLogo(_ data: Data?) {
        profile.logo = data
        saved = false
    }

    func save() {
        state = .loading
        do {
            try saveBusinessProfile.execute(profile)
            saved = true
            state = .loaded
        } catch {
            saved = false
            state = .failed(AppErrorMapper.message(for: error))
        }
    }
}
