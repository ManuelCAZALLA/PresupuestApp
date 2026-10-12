import Foundation

/// Guarda el perfil de empresa (configuración única).
public final class SaveBusinessProfile {
    private let profile: ProfileRepository

    public init(profile: ProfileRepository) {
        self.profile = profile
    }

    public func execute(_ profile: BusinessProfile) throws {
        try self.profile.save(profile)
    }
}
