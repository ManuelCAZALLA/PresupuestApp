import Foundation

/// Lista las partidas del catálogo.
public final class ListItems {
    private let items: ItemRepository

    public init(items: ItemRepository) {
        self.items = items
    }

    public func execute() throws -> [Item] {
        try items.all()
    }
}
