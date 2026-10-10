import SwiftUI

/// App root: hosts the NavigationStack bound to the injected router.
struct AppRootView: View {
    let container: AppContainer
    @State private var router = AppRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
        }
        .environment(router)
    }
}

#Preview {
    AppRootView(container: AppContainer())
}
