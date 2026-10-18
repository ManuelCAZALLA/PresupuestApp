import Foundation
import SwiftData
import QuoteCore
import os

/// Raíz de composición: crea las implementaciones concretas de los
/// puertos y los casos de uso, y los inyecta (a mano, sin librerías).
@MainActor
final class AppContainer {
    let router = AppRouter()
    let session: AppSession

    let onboardingViewModel: OnboardingViewModel
    let catalogViewModel: CatalogViewModel
    let importTariffViewModel: ImportTariffViewModel
    let settingsViewModel: SettingsViewModel
    let quoteListViewModel: QuoteListViewModel

    private let loadQuote: LoadQuote
    private let updateQuote: UpdateQuote
    private let addLine: AddLine
    private let updateLineQuantity: UpdateLineQuantity
    private let removeLine: RemoveLine
    private let listItems: ListItems
    private let exportQuotePDF: ExportQuotePDF
    private let changeQuoteStatus: ChangeQuoteStatus

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

        let createQuote = CreateQuote(
            quotes: quoteRepository,
            profile: profileRepository,
            clock: clock as Clock,
            entitlements: entitlements
        )
        let duplicateQuote = DuplicateQuote(
            quotes: quoteRepository,
            profile: profileRepository,
            clock: clock as Clock
        )

        self.loadQuote = LoadQuote(quotes: quoteRepository)
        self.updateQuote = UpdateQuote(quotes: quoteRepository)
        self.addLine = AddLine(quotes: quoteRepository, items: itemRepository)
        self.updateLineQuantity = UpdateLineQuantity(quotes: quoteRepository)
        self.removeLine = RemoveLine(quotes: quoteRepository)
        self.listItems = listItems
        self.changeQuoteStatus = ChangeQuoteStatus(quotes: quoteRepository)
        self.exportQuotePDF = ExportQuotePDF(
            renderer: DeviceQuotePDFRenderer(),
            profile: profileRepository,
            entitlements: entitlements
        )

        self.session = AppSession(loadBusinessProfile: loadBusinessProfile)
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
        self.quoteListViewModel = QuoteListViewModel(
            listQuotes: ListQuotes(quotes: quoteRepository),
            createQuote: createQuote,
            duplicateQuote: duplicateQuote
        )
    }

    func makeQuoteEditorViewModel(id: UUID) -> QuoteEditorViewModel {
        QuoteEditorViewModel(
            quoteID: id,
            loadQuote: loadQuote,
            updateQuote: updateQuote,
            addLine: addLine,
            updateLineQuantity: updateLineQuantity,
            removeLine: removeLine,
            listItems: listItems
        )
    }

    func makeQuotePreviewViewModel(id: UUID) -> QuotePreviewViewModel {
        QuotePreviewViewModel(
            quoteID: id,
            loadQuote: loadQuote,
            exportQuotePDF: exportQuotePDF,
            changeQuoteStatus: changeQuoteStatus
        )
    }
}

extension Logger {
    static let app = Logger(subsystem: "com.manuelcazalla.PresupuestApp", category: "app")
}
