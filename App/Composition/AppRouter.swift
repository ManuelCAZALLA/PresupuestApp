import Observation
import SwiftUI

enum AppTab: Hashable {
    case quotes
    case prices
    case settings
}

/// Rutas empujadas dentro de la pestaña Presupuestos (ver docs/DECISIONS.md, D-013).
enum AppRoute: Hashable {
    case quoteEditor(UUID)
    case quotePreview(UUID)
}

/// Dueña del estado de navegación. Se crea en la raíz de composición
/// y se inyecta en el árbol de vistas.
@Observable
final class AppRouter {
    var selectedTab: AppTab = .quotes
    var quotesPath = NavigationPath()
    var isImportPresented = false
    var isItemEditorPresented = false

    func openQuote(_ id: UUID) {
        selectedTab = .quotes
        quotesPath.append(AppRoute.quoteEditor(id))
    }

    func openPreview(_ id: UUID) {
        quotesPath.append(AppRoute.quotePreview(id))
    }

    func presentImport() {
        selectedTab = .prices
        isImportPresented = true
    }

    /// Abre el editor de una partida nueva. Lo presenta la raíz para que
    /// funcione igual desde el catálogo y desde el onboarding.
    func presentNewItem() {
        selectedTab = .prices
        isItemEditorPresented = true
    }

    func popQuotesToRoot() {
        quotesPath = NavigationPath()
    }
}
