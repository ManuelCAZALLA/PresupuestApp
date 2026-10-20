import Foundation
import QuoteCore
import Testing
@testable import PresupuestApp

/// S1 (Onboarding): pasos, datos del negocio, IVA por defecto y bandera de
/// finalización. La suite es serial porque comparte una suite de `UserDefaults`.
@Suite("Onboarding", .serialized)
@MainActor
struct OnboardingViewModelTests {
    @Test("Empieza en el paso 1 y avanza y retrocede")
    func navigatesSteps() throws {
        let viewModel = makeOnboarding()

        #expect(viewModel.step == .tariff)
        #expect(viewModel.isFirstStep)

        viewModel.next()
        #expect(viewModel.step == .estimate)
        viewModel.next()
        #expect(viewModel.step == .send)
        viewModel.next()
        #expect(viewModel.step == .business)
        #expect(viewModel.isFirstStep == false)

        viewModel.back()
        #expect(viewModel.step == .send)
        viewModel.back()
        #expect(viewModel.step == .estimate)
    }

    @Test("Saltar lleva al paso 4 y el carrusel se puede retomar")
    func skipGoesToBusiness() throws {
        let viewModel = makeOnboarding()

        #expect(viewModel.showsSkip)
        viewModel.next()
        viewModel.skip()

        #expect(viewModel.step == .business)
        #expect(viewModel.showsSkip == false)
        #expect(viewModel.showsPageIndicator == false)

        viewModel.back()
        #expect(viewModel.step == .send)
        #expect(viewModel.showsSkip)
        #expect(viewModel.showsPageIndicator)
    }

    @Test("El indicador cuenta los tres pasos del carrusel")
    func pageIndicatorCountsCarousel() throws {
        let viewModel = makeOnboarding()

        #expect(viewModel.pageCount == 3)
        #expect(viewModel.pageIndex == 0)
        viewModel.next()
        #expect(viewModel.pageIndex == 1)
        viewModel.next()
        #expect(viewModel.pageIndex == 2)
    }

    @Test("Continuar solo se activa con nombre")
    func continueNeedsName() throws {
        let viewModel = makeOnboarding()
        viewModel.skip()

        #expect(viewModel.canContinue == false)
        viewModel.name = "   "
        #expect(viewModel.canContinue == false)
        viewModel.name = "Fontanería Pérez"
        #expect(viewModel.canContinue)
    }

    @Test("El IVA por defecto es el 21 % y se puede cambiar")
    func defaultVATRate() throws {
        let viewModel = makeOnboarding()
        viewModel.skip()

        #expect(viewModel.vatChoice == .standard)
        #expect(viewModel.defaultVATRate == Decimal(21))

        viewModel.vatChoice = .reduced
        #expect(viewModel.defaultVATRate == Decimal(10))

        viewModel.vatChoice = .other
        viewModel.otherVATRateText = "5,5"
        #expect(viewModel.defaultVATRate == Decimal(string: "5.5"))
        #expect(viewModel.isOtherVATRateInvalid == false)

        viewModel.otherVATRateText = "cinco"
        #expect(viewModel.isOtherVATRateInvalid)
        #expect(viewModel.defaultVATRate == Decimal(21))
    }

    @Test("Continuar guarda el negocio y pasa al catálogo vacío")
    func savesBusinessAndGoesToCatalog() throws {
        let profiles = StubProfileRepository()
        let viewModel = makeOnboarding(profiles: profiles)
        viewModel.skip()
        viewModel.name = "  Fontanería Pérez  "
        viewModel.taxID = "12345678Z"
        viewModel.phone = "600 000 000"
        viewModel.vatChoice = .reduced

        viewModel.continueFromBusiness()

        #expect(viewModel.state == .saved)
        #expect(viewModel.step == .loadTariff)
        let saved = try #require(profiles.saved.first)
        #expect(saved.name == "Fontanería Pérez")
        #expect(saved.taxID == "12345678Z")
        #expect(saved.phone == "600 000 000")
        #expect(saved.defaultVATRate == Decimal(10))
    }

    @Test("Sin nombre no se guarda ni se avanza")
    func continueWithoutNameDoesNothing() throws {
        let profiles = StubProfileRepository()
        let viewModel = makeOnboarding(profiles: profiles)
        viewModel.skip()

        viewModel.continueFromBusiness()

        #expect(viewModel.step == .business)
        #expect(viewModel.state == .idle)
        #expect(profiles.saved.isEmpty)
    }

    @Test("Si falla el guardado, se queda en el paso 4 con el aviso")
    func saveFailureStaysOnBusiness() throws {
        let profiles = StubProfileRepository()
        profiles.error = TestError()
        let viewModel = makeOnboarding(profiles: profiles)
        viewModel.skip()
        viewModel.name = "Taller"

        viewModel.continueFromBusiness()

        #expect(viewModel.step == .business)
        var failed = false
        if case .failed = viewModel.state { failed = true }
        #expect(failed)
    }

    @Test("Elegir una opción o «Lo haré luego» termina el onboarding y marca la bandera")
    func finishingMarksTheFlag() throws {
        let profiles = StubProfileRepository()
        let defaults = try makeDefaults()
        let session = makeSession(profiles: profiles, defaults: defaults)
        let viewModel = makeOnboarding(profiles: profiles) { session.completeOnboarding() }

        #expect(session.isOnboarded == false)

        viewModel.skip()
        viewModel.name = "Taller"
        viewModel.continueFromBusiness()
        viewModel.start(with: .importTariff)

        #expect(viewModel.startOption == .importTariff)
        #expect(session.isOnboarded)
        #expect(profiles.saved.count == 1)

        // Una sesión nueva con los mismos ajustes ya no muestra el onboarding.
        let reopened = makeSession(profiles: profiles, defaults: defaults)
        #expect(reopened.isOnboarded)
    }

    @Test("«Lo haré luego» termina el onboarding aunque no se cargue nada")
    func laterAlsoFinishes() throws {
        let profiles = StubProfileRepository()
        let defaults = try makeDefaults()
        let session = makeSession(profiles: profiles, defaults: defaults)
        let viewModel = makeOnboarding(profiles: profiles) { session.completeOnboarding() }

        viewModel.skip()
        viewModel.name = "Taller"
        viewModel.continueFromBusiness()
        viewModel.start(with: .later)

        #expect(viewModel.startOption == .later)
        #expect(session.isOnboarded)
    }

    @Test("«Cómo funciona» solo muestra los pasos 1–3 y no toca la bandera")
    func walkthroughDoesNotChangeTheFlag() throws {
        let profiles = StubProfileRepository()
        let defaults = try makeDefaults()
        let session = makeSession(profiles: profiles, defaults: defaults)

        let onboarding = makeOnboarding(profiles: profiles) { session.completeOnboarding() }
        onboarding.skip()
        onboarding.name = "Taller"
        onboarding.continueFromBusiness()
        onboarding.start(with: .later)
        #expect(session.isOnboarded)

        var completions = 0
        let walkthrough = OnboardingViewModel(
            mode: .walkthrough,
            saveBusinessProfile: SaveBusinessProfile(profile: profiles),
            onComplete: { completions += 1 }
        )

        #expect(walkthrough.visibleSteps == [.tariff, .estimate, .send])
        #expect(walkthrough.showsSkip == false)
        #expect(walkthrough.step == .tariff)

        walkthrough.next()
        walkthrough.next()
        #expect(walkthrough.step == .send)
        walkthrough.primaryAction()
        #expect(walkthrough.step == .send)

        #expect(completions == 0)
        #expect(session.isOnboarded)
    }

    @Test("Un negocio ya guardado cuenta como onboarding hecho")
    func existingProfileCountsAsOnboarded() throws {
        let profiles = StubProfileRepository()
        profiles.stored = BusinessProfile(name: "Taller de antes")
        let defaults = try makeDefaults()

        let session = makeSession(profiles: profiles, defaults: defaults)

        #expect(session.isOnboarded)
    }

    // MARK: - Ayudas

    private func makeOnboarding(
        profiles: StubProfileRepository = StubProfileRepository(),
        onComplete: @escaping () -> Void = {}
    ) -> OnboardingViewModel {
        OnboardingViewModel(
            mode: .onboarding,
            saveBusinessProfile: SaveBusinessProfile(profile: profiles),
            onComplete: onComplete
        )
    }

    private func makeSession(
        profiles: StubProfileRepository,
        defaults: UserDefaults
    ) -> AppSession {
        AppSession(
            loadBusinessProfile: LoadBusinessProfile(profile: profiles),
            defaults: defaults
        )
    }

    private func makeDefaults() throws -> UserDefaults {
        let name = "presupuestapp.onboarding.tests"
        let defaults = try #require(UserDefaults(suiteName: name))
        defaults.removePersistentDomain(forName: name)
        return defaults
    }
}

private struct TestError: Error {}

/// Devuelve al cargar solo lo que se le ponga a mano (`stored`), nunca lo
/// que guarda, para que la bandera del onboarding no pueda venir del perfil.
private final class StubProfileRepository: ProfileRepository {
    var stored: BusinessProfile?
    var error: Error?
    private(set) var saved: [BusinessProfile] = []

    func load() throws -> BusinessProfile? { stored }

    func save(_ profile: BusinessProfile) throws {
        if let error { throw error }
        saved.append(profile)
    }
}
