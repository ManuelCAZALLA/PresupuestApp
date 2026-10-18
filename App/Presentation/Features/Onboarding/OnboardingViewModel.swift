import Foundation
import Observation
import QuoteCore

/// Vista modelo de S1 (Onboarding): elige oficio, datos de empresa
/// e IVA por defecto. NO siembra partidas: el catálogo arranca vacío
/// y el usuario carga su tarifa (ver DECISIONS.md, D-007).
@MainActor
@Observable
final class OnboardingViewModel {
    enum ViewState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var state: ViewState = .idle
    private(set) var profile = BusinessProfile()
    private(set) var trade: Trade = .plumber

    private let saveBusinessProfile: SaveBusinessProfile

    init(saveBusinessProfile: SaveBusinessProfile) {
        self.saveBusinessProfile = saveBusinessProfile
    }

    func selectTrade(_ trade: Trade) {
        self.trade = trade
    }

    func updateProfile(
        name: String,
        taxID: String,
        phone: String,
        email: String,
        defaultVATRate: Decimal,
        terms: String,
        validityDays: Int,
        numberPrefix: String
    ) {
        profile = BusinessProfile(
            name: name,
            taxID: taxID,
            phone: phone,
            email: email,
            defaultVATRate: defaultVATRate,
            terms: terms,
            validityDays: validityDays,
            numberPrefix: numberPrefix
        )
    }

    /// Guarda el perfil de empresa. No inserta ninguna partida: la
    /// tarifa la carga el usuario (importar, pegar o a mano).
    func save() {
        state = .loading
        do {
            try saveBusinessProfile.execute(profile)
            state = .loaded
        } catch {
            state = .failed(AppErrorMapper.message(for: error))
        }
    }
}
