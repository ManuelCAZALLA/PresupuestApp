import Foundation

/// Crea, edita y borra agrupaciones (kits) del catálogo (ver docs/DOMAIN.md).
public final class ManageKits {
    public enum Operation: Equatable {
        case create(Kit)
        case update(Kit)
        case delete(UUID)
    }

    private let kits: KitRepository

    public init(kits: KitRepository) {
        self.kits = kits
    }

    public func execute(_ operation: Operation) throws {
        switch operation {
        case .create(let kit), .update(let kit):
            try kits.save(kit)
        case .delete(let id):
            try kits.delete(id: id)
        }
    }
}
