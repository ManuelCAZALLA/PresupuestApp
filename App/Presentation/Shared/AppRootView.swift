import SwiftUI

/// App root: hosts the NavigationStack bound to the router created in Composition.
struct AppRootView: View {
    @Bindable var router: AppRouter

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
        }
        .environment(router)
    }
}

#Preview {
    AppRootView(router: AppRouter())
}
