import SwiftUI

@main
struct PresupuestApp: App {
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            AppRootView(router: container.router)
        }
    }
}
