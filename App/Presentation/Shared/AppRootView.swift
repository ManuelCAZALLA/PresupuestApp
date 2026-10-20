import SwiftUI

/// Raíz: onboarding a pantalla completa o pestañas según D-013.
struct AppRootView: View {
    let container: AppContainer
    @Bindable var router: AppRouter
    @Bindable var session: AppSession

    init(container: AppContainer) {
        self.container = container
        self._router = Bindable(wrappedValue: container.router)
        self._session = Bindable(wrappedValue: container.session)
    }

    var body: some View {
        Group {
            if session.isOnboarded {
                tabs
            } else {
                OnboardingView(
                    viewModel: container.onboardingViewModel,
                    router: router
                )
            }
        }
        .tint(Color.accentColor)
        .environment(router)
        .sheet(isPresented: $router.isImportPresented) {
            NavigationStack {
                ImportTariffView(viewModel: container.importTariffViewModel)
            }
        }
        .sheet(isPresented: $router.isItemEditorPresented) {
            NavigationStack {
                ItemEditorView { created in
                    container.catalogViewModel.saveItem(created, isNew: true)
                }
            }
            .presentationDetents([.large])
        }
        .onChange(of: router.isImportPresented) { _, presented in
            if !presented {
                container.importTariffViewModel.reset()
            }
        }
        .onOpenURL { url in
            container.importTariffViewModel.openExternalFile(at: url)
            router.presentImport()
        }
    }

    private var tabs: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.quotesPath) {
                QuoteListView(viewModel: container.quoteListViewModel)
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .quoteEditor(let id):
                            QuoteEditorScreen(viewModel: container.makeQuoteEditorViewModel(id: id))
                        case .quotePreview(let id):
                            QuotePreviewScreen(viewModel: container.makeQuotePreviewViewModel(id: id))
                        }
                    }
            }
            .tabItem {
                Label("tab.quotes", systemImage: "doc.text")
            }
            .tag(AppTab.quotes)

            NavigationStack {
                CatalogView(viewModel: container.catalogViewModel)
            }
            .tabItem {
                Label("tab.prices", systemImage: "tag")
            }
            .tag(AppTab.prices)

            NavigationStack {
                SettingsView(
                    viewModel: container.settingsViewModel,
                    makeWalkthroughViewModel: container.makeWalkthroughViewModel
                )
            }
            .tabItem {
                Label("tab.settings", systemImage: "gearshape")
            }
            .tag(AppTab.settings)
        }
    }
}
