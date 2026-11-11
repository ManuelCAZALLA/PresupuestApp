import SwiftUI

/// Raíz: onboarding a pantalla completa o pestañas según D-013 y D-021.
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
        .sheet(isPresented: $router.isSettingsPresented) {
            settingsSheet
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
                    .settingsToolbarButton()
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
                    .settingsToolbarButton()
            }
            .tabItem {
                Label("tab.prices", systemImage: "tag")
            }
            .tag(AppTab.prices)

            NavigationStack {
                KitsView(viewModel: container.kitsViewModel)
                    .settingsToolbarButton()
            }
            .tabItem {
                Label("tab.kits", systemImage: "square.stack.3d.up")
            }
            .tag(AppTab.kits)

            NavigationStack {
                ClientsView(viewModel: container.clientsViewModel)
                    .settingsToolbarButton()
            }
            .tabItem {
                Label("tab.clients", systemImage: "person.2")
            }
            .tag(AppTab.clients)
        }
    }

    /// Ajustes se abre desde el engranaje de la esquina superior derecha,
    /// no ocupa una pestaña (D-021).
    private var settingsSheet: some View {
        NavigationStack {
            SettingsView(
                viewModel: container.settingsViewModel,
                makeWalkthroughViewModel: container.makeWalkthroughViewModel
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.close") {
                        router.isSettingsPresented = false
                    }
                }
            }
        }
        .environment(router)
        .presentationDetents([.large])
    }
}
