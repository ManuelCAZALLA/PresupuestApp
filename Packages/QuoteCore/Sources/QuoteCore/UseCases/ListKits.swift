import Foundation

/// Lista las agrupaciones (kits) disponibles.
public final class ListKits {
    private let kits: KitRepository

    public init(kits: KitRepository) {
        self.kits = kits
    }

    public func execute() throws -> [Kit] {
        try kits.all()
    }
}
