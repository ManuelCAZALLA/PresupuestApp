import SwiftUI

/// Raíz de la app: NavigationStack con un destino por ruta.
struct AppRootView: View {
    let container: AppContainer
    @Bindable var router: AppRouter

    init(container: AppContainer) {
        self.container = container
        self._router = Bindable(wrappedValue: container.router)
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .onboarding:
                        OnboardingView(viewModel: container.onboardingViewModel)
                    case .catalog:
                        CatalogView(viewModel: container.catalogViewModel)
                    case .importTariff:
                        ImportTariffView()
                    case .settings:
                        SettingsView(viewModel: container.settingsViewModel)
                    }
                }
        }
        .environment(router)
    }
}
