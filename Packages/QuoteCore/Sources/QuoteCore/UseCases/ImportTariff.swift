import Foundation

/// Aplica al catálogo las filas ya revisadas por el usuario (S8). Nunca se
/// llama antes de la pantalla de revisión (ver docs/PRODUCT.md y D-007/D-008).
public final class ImportTariff {
    /// Cuántas partidas se crearon, se actualizaron o se saltaron.
    public struct Summary: Equatable, Sendable {
        public var created: Int
        public var updated: Int
        public var skipped: Int

        public init(created: Int = 0, updated: Int = 0, skipped: Int = 0) {
            self.created = created
            self.updated = updated
            self.skipped = skipped
        }
    }

    private let items: ItemRepository

    public init(items: ItemRepository) {
        self.items = items
    }

    public func execute(
        rows: [ImportedRow],
        mode: ImportMode = .updateExisting
    ) throws -> Summary {
        var summary = Summary()
        var handled: Set<String> = []

        for row in rows {
            let key = Item.nameKey(row.name)
            guard !key.isEmpty else { continue }

            // Un mismo nombre repetido en el archivo no se aplica dos veces.
            guard handled.insert(key).inserted else {
                summary.skipped += 1
                continue
            }

            if let existing = try items.item(named: row.name) {
                guard mode == .updateExisting else {
                    summary.skipped += 1
                    continue
                }
                var updated = existing
                updated.name = row.name
                updated.unit = row.unit
                updated.unitPrice = row.netPrice
                updated.kind = row.kind
                updated.category = row.category ?? existing.category
                try items.save(updated)
                summary.updated += 1
            } else {
                try items.save(row.item())
                summary.created += 1
            }
        }

        return summary
    }
}
