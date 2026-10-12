import Foundation

/// Carga el perfil de empresa, si existe.
public final class LoadBusinessProfile {
    private let profile: ProfileRepository

    public init(profile: ProfileRepository) {
        self.profile = profile
    }

    public func execute() throws -> BusinessProfile? {
        try profile.load()
    }
}
