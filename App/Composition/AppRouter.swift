import Observation
import SwiftUI

/// Rutas tipadas de la app: una por pantalla (ver docs/PRODUCT.md).
enum AppRoute: Hashable {
    case onboarding
    case catalog
    case importTariff
    case settings
}

/// Dueña del estado de navegación. Se crea en la raíz de composición
/// y se inyecta en el árbol de vistas.
@Observable
final class AppRouter {
    var path = NavigationPath()

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
