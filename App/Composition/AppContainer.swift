/// Composition root. Manual dependency injection.
///
/// The router is created here and injected into the view tree. Repositories,
/// use cases and services are wired here from later milestones.
final class AppContainer {
    let router = AppRouter()
}
