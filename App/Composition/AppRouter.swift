import Observation
import SwiftUI

/// Typed navigation routes. Empty in M0; one case per screen as features are added.
enum AppRoute: Hashable {
}

/// Owns the navigation state. Created at the composition root and injected into the view tree.
///
/// `push(_:)` is added together with the first `AppRoute` cases; with an empty
/// enum the compiler would flag the route append as unreachable code.
@Observable
final class AppRouter {
    var path = NavigationPath()

    func popToRoot() {
        path = NavigationPath()
    }
}
