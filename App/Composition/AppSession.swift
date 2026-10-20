import Foundation
import Observation
import QuoteCore
import os

/// Estado de sesión: la app muestra el onboarding mientras no esté puesta
/// la bandera `hasCompletedOnboarding` (ver docs/DECISIONS.md, D-016).
@MainActor
@Observable
final class AppSession {
    /// Bandera en `UserDefaults`: la inyecta la raíz de composición.
    private static let completionKey = "hasCompletedOnboarding"

    private(set) var isOnboarded: Bool

    private let loadBusinessProfile: LoadBusinessProfile
    private let defaults: UserDefaults

    init(loadBusinessProfile: LoadBusinessProfile, defaults: UserDefaults) {
        self.loadBusinessProfile = loadBusinessProfile
        self.defaults = defaults
        self.isOnboarded = false
        refresh()
    }

    /// Quien ya tiene perfil de negocio tiene el onboarding hecho: así no
    /// se le vuelve a mostrar tras una actualización (D-016).
    func refresh() {
        let profile: BusinessProfile?
        do {
            profile = try loadBusinessProfile.execute()
        } catch {
            Logger.app.error("No se pudo leer el perfil de empresa: \(error.localizedDescription, privacy: .public)")
            profile = nil
        }

        if profile != nil {
            defaults.set(true, forKey: Self.completionKey)
        }
        isOnboarded = defaults.bool(forKey: Self.completionKey)
    }

    func completeOnboarding() {
        defaults.set(true, forKey: Self.completionKey)
        isOnboarded = true
    }
}
