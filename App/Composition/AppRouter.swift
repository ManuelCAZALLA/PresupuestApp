import Observation
import SwiftUI

/// Typed navigation routes. Empty in M0; one case per screen as features are added.
enum AppRoute: Hashable {
}

/// Owns the navigation state. Created at the composition root and injected into the view tree.
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
