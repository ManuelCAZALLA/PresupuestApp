import Foundation
import QuoteCore

/// Carga los packs de oficio desde el bundle (JSON, SIN precios).
public final class BundleTradePackLoader: TradePackLoading {
    private let bundle: Bundle

    public init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    public func load(trade: Trade) throws -> TradePackData {
        let fileName: String
        switch trade {
        case .plumber: fileName = "pack_fontaneria"
        case .mason: fileName = "pack_albanileria"
        case .electrician: fileName = "pack_electricidad"
        case .other: throw DomainError.packNotFound(trade)
        }

        guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
            throw DomainError.packNotFound(trade)
        }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw DomainError.packNotFound(trade)
        }

        let dto: TradePackDTO
        do {
            dto = try JSONDecoder().decode(TradePackDTO.self, from: data)
        } catch {
            throw DomainError.packNotFound(trade)
        }

        var entries: [TradePackEntry] = []
        for item in dto.items {
            // Si el JSON tiene una unidad o tipo inválidos, el pack no
            // es usable: se lanza en lugar de asignar valores a ciegas.
            guard let unit = MeasureUnit(rawValue: item.unit),
                  let kind = ItemKind(rawValue: item.kind) else {
                throw DomainError.packNotFound(trade)
            }
            entries.append(
                TradePackEntry(
                    name: item.name,
                    unit: unit,
                    kind: kind,
                    category: item.category,
                    aliases: item.aliases
                )
            )
        }
        return TradePackData(trade: trade, entries: entries)
    }
}

private struct TradePackDTO: Decodable {
    let items: [ItemDTO]

    struct ItemDTO: Decodable {
        let name: String
        let unit: String
        let kind: String
        let category: String?
        let aliases: [String]
    }
}
