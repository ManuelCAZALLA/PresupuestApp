import Foundation
import Observation
import QuoteCore

/// Vista modelo de S1 (Onboarding): cinco pasos —carrusel, datos del
/// negocio y catálogo vacío— en dos modos: el onboarding real y el paseo
/// que abre Ajustes con "Cómo funciona", que nunca marca la bandera
/// (ver docs/DECISIONS.md, D-016). NO siembra partidas: el catálogo
/// arranca vacío y el usuario carga su tarifa (D-007).
@MainActor
@Observable
final class OnboardingViewModel {
    enum Mode: Equatable {
        /// Recorrido completo: termina marcando el onboarding como hecho.
        case onboarding
        /// Solo el carrusel (pasos 1–3), desde Ajustes → "Cómo funciona".
        case walkthrough
    }

    enum Step: Int, CaseIterable, Equatable {
        case tariff
        case estimate
        case send
        case business
        case loadTariff
    }

    enum ViewState: Equatable {
        case idle
        case saving
        case saved
        case failed(String)
    }

    /// IVA por defecto del perfil: 21 % preseleccionado, 10 % y "Otro".
    enum VATChoice: Hashable {
        case standard
        case reduced
        case other
    }

    /// Último paso: por dónde empieza a cargar la tarifa. Cualquiera de
    /// las opciones —también "Lo haré luego"— termina el onboarding.
    enum StartOption: Hashable {
        case importTariff
        case pasteList
        case addManually
        case later
    }

    let mode: Mode

    private(set) var step: Step = .tariff
    private(set) var state: ViewState = .idle
    private(set) var startOption: StartOption?
    private(set) var logo: Data?

    // Paso 4: datos del negocio.
    var name = ""
    var taxID = ""
    var phone = ""
    var vatChoice: VATChoice = .standard
    var otherVATRateText = ""

    private static let carouselSteps: [Step] = [.tariff, .estimate, .send]

    private let saveBusinessProfile: SaveBusinessProfile
    private let onComplete: () -> Void

    init(
        mode: Mode,
        saveBusinessProfile: SaveBusinessProfile,
        onComplete: @escaping () -> Void = {}
    ) {
        self.mode = mode
        self.saveBusinessProfile = saveBusinessProfile
        self.onComplete = onComplete
    }

    // MARK: - Navegación

    /// Los pasos que se ven en este modo: el carrusel solo, o los cinco.
    var visibleSteps: [Step] {
        mode == .walkthrough ? Self.carouselSteps : Step.allCases
    }

    var isFirstStep: Bool { step == visibleSteps.first }
    var isLastVisibleStep: Bool { step == visibleSteps.last }

    /// "Saltar" solo existe en el carrusel del onboarding real.
    var showsSkip: Bool { mode == .onboarding && Self.carouselSteps.contains(step) }

    var showsPageIndicator: Bool { Self.carouselSteps.contains(step) }
    var pageCount: Int { Self.carouselSteps.count }
    var pageIndex: Int { Self.carouselSteps.firstIndex(of: step) ?? 0 }

    /// Título del botón principal; `nil` en el último paso, donde la
    /// acción la dan las tarjetas y "Lo haré luego".
    var primaryTitleKey: String? {
        switch mode {
        case .walkthrough:
            return isLastVisibleStep ? "action.close" : "onboarding.next"
        case .onboarding:
            switch step {
            case .tariff, .estimate: return "onboarding.next"
            case .send: return "onboarding.start"
            case .business: return "onboarding.continue"
            case .loadTariff: return nil
            }
        }
    }

    var isPrimaryEnabled: Bool { step == .business ? canContinue : true }

    func next() {
        guard let index = visibleSteps.firstIndex(of: step),
              visibleSteps.indices.contains(index + 1) else { return }
        step = visibleSteps[index + 1]
    }

    func back() {
        guard let index = visibleSteps.firstIndex(of: step), index > 0 else { return }
        step = visibleSteps[index - 1]
    }

    /// "Saltar" lleva directo al paso 4 (los datos del negocio).
    func skip() {
        step = .business
    }

    func primaryAction() {
        switch step {
        case .tariff, .estimate, .send: next()
        case .business: continueFromBusiness()
        case .loadTariff: break
        }
    }

    // MARK: - Paso 4: datos del negocio

    var canContinue: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var defaultVATRate: Decimal {
        switch vatChoice {
        case .standard: return Decimal(21)
        case .reduced: return Decimal(10)
        case .other: return Self.rate(from: otherVATRateText) ?? Decimal(21)
        }
    }

    /// "Otro" con un tipo ilegible: se avisa en vez de elegir en silencio.
    var isOtherVATRateInvalid: Bool {
        vatChoice == .other
            && !otherVATRateText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && Self.rate(from: otherVATRateText) == nil
    }

    /// El perfil que se guarda: el resto de campos (condiciones, validez y
    /// numeración) se ajustan en Ajustes con sus valores por defecto.
    var profile: BusinessProfile {
        BusinessProfile(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            taxID: taxID.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
            logo: logo,
            defaultVATRate: defaultVATRate
        )
    }

    func setLogo(_ data: Data?) {
        logo = data
    }

    /// Guarda el perfil y pasa al catálogo vacío (paso 5).
    func continueFromBusiness() {
        guard canContinue else { return }
        state = .saving
        do {
            try saveBusinessProfile.execute(profile)
            state = .saved
            step = .loadTariff
        } catch {
            state = .failed(AppErrorMapper.message(for: error))
        }
    }

    // MARK: - Paso 5: cargar la tarifa

    /// Termina el onboarding. En el paseo de Ajustes no hace nada.
    func start(with option: StartOption) {
        guard mode == .onboarding, step == .loadTariff else { return }
        startOption = option
        onComplete()
    }

    private static func rate(from text: String) -> Decimal? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Decimal(string: normalized), value >= 0 else { return nil }
        return value
    }
}
