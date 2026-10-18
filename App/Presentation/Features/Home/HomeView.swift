import SwiftUI

/// Pantalla inicial: acceso a las pantallas del MVP.
struct HomeView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        List {
            Section {
                Button {
                    router.push(.onboarding)
                } label: {
                    Label("home.onboarding", systemImage: "person.badge.gearshape")
                }
                Button {
                    router.push(.catalog)
                } label: {
                    Label("home.catalog", systemImage: "tag")
                }
                Button {
                    router.push(.settings)
                } label: {
                    Label("home.settings", systemImage: "gearshape")
                }
            }
        }
        .navigationTitle("home.title")
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environment(AppRouter())
    }
}
