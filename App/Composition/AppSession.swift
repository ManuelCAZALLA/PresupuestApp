import Foundation
import Observation
import QuoteCore

/// Estado de sesión: si no hay perfil de negocio, la app muestra el onboarding.
@MainActor
@Observable
final class AppSession {
    private(set) var isOnboarded = false

    private let loadBusinessProfile: LoadBusinessProfile

    init(loadBusinessProfile: LoadBusinessProfile) {
        self.loadBusinessProfile = loadBusinessProfile
        refresh()
    }

    func refresh() {
        isOnboarded = (try? loadBusinessProfile.execute()) != nil
    }

    func completeOnboarding() {
        isOnboarded = true
    }
}
