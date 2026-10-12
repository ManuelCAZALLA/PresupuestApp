import Foundation

/// Carga el pack de un oficio y crea sus partidas SIN precio:
/// los precios los pone el usuario (ver docs/PRODUCT.md).
public final class LoadTradePack {
    private let loader: TradePackLoading

    public init(loader: TradePackLoading) {
        self.loader = loader
    }

    public func execute(trade: Trade) throws -> [Item] {
        let pack = try loader.load(trade: trade)
        return pack.entries.map { entry in
            Item(
                name: entry.name,
                aliases: entry.aliases,
                unit: entry.unit,
                unitPrice: Decimal(0),
                kind: entry.kind,
                category: entry.category,
                trade: pack.trade
            )
        }
    }
}
