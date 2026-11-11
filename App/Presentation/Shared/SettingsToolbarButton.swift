import SwiftUI

/// Engranaje de la esquina superior derecha: abre Ajustes como hoja.
struct SettingsToolbarButton: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        Button {
            router.presentSettings()
        } label: {
            Label("tab.settings", systemImage: "gearshape")
        }
    }
}

extension View {
    /// Añade el acceso a Ajustes a la barra de navegación de una pestaña.
    func settingsToolbarButton() -> some View {
        toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SettingsToolbarButton()
            }
        }
    }
}
