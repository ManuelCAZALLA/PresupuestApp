import os
import SwiftUI

@main
struct PresupuestApp: App {
    private let container: AppContainer?

    init() {
        do {
            container = try AppContainer()
        } catch {
            Logger.app.error("No se pudo arrancar la app: \(error.localizedDescription)")
            container = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                AppRootView(container: container)
            } else {
                ContentUnavailableView(
                    "error.persistence.title",
                    systemImage: "exclamationmark.triangle"
                )
            }
        }
    }
}

