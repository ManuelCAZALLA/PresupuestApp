import Foundation
import SwiftData
import QuoteCore
import os

/// Raíz de composición: crea las implementaciones concretas de los
/// puertos y los casos de uso, y los inyecta (a mano, sin librerías).
@MainActor
final class AppContainer {
    let router = AppRouter()

    let onboardingViewModel: OnboardingViewModel
    let catalogViewModel: CatalogViewModel
    let importTariffViewModel: ImportTariffViewModel
    let settingsViewModel: SettingsViewModel

    /// Casos de uso de presupuestos: M5 los consume desde las pantallas.
    let createQuote: CreateQuote
    let duplicateQuote: DuplicateQuote
    let changeQuoteStatus: ChangeQuoteStatus
    let checkQuota: CheckQuota

    init() throws {
        let modelContainer = try PersistenceSetup.makeModelContainer()

        let itemRepository = SwiftDataItemRepository(container: modelContainer)
        let quoteRepository = SwiftDataQuoteRepository(container: modelContainer)
        let profileRepository = SwiftDataProfileRepository(container: modelContainer)

        let loadBusinessProfile = LoadBusinessProfile(profile: profileRepository)
        let saveBusinessProfile = SaveBusinessProfile(profile: profileRepository)
        let listItems = ListItems(items: itemRepository)
        let manageItems = ManageItems(items: itemRepository)

        let clock = SystemClock()
        let entitlements = StubEntitlements()

        self.createQuote = CreateQuote(
            quotes: quoteRepository,
            profile: profileRepository,
            clock: clock as Clock,
            entitlements: entitlements
        )
        self.duplicateQuote = DuplicateQuote(
            quotes: quoteRepository,
            profile: profileRepository,
            clock: clock as Clock )
        self.changeQuoteStatus = ChangeQuoteStatus(quotes: quoteRepository)
        self.checkQuota = CheckQuota(
            quotes: quoteRepository,
            clock: clock as Clock,
            entitlements: entitlements
        )

        self.onboardingViewModel = OnboardingViewModel(
            saveBusinessProfile: saveBusinessProfile
        )
        self.catalogViewModel = CatalogViewModel(
            listItems: listItems,
            manageItems: manageItems
        )
        self.importTariffViewModel = ImportTariffViewModel(
            source: LocalTariffSource(),
            template: FileTariffTemplateProvider(),
            importTariff: ImportTariff(items: itemRepository)
        )
        self.settingsViewModel = SettingsViewModel(
            loadBusinessProfile: loadBusinessProfile,
            saveBusinessProfile: saveBusinessProfile
        )
    }
}

extension Logger {
    static let app = Logger(subsystem: "com.manuelcazalla.PresupuestApp", category: "app")
}
