import Foundation
@testable import QuoteCore

// MARK: - Helpers (compartidos por todo el target de tests)

func makeUTCDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0, _ second: Int = 0) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    components.second = second
    components.timeZone = TimeZone(secondsFromGMT: 0)
    return Calendar(identifier: .gregorian).date(from: components)!
}

func d(_ s: String) -> Decimal {
    Decimal(string: s)!
}

// MARK: - Fakes

final class FakeItemRepository: ItemRepository {
    var items: [UUID: Item] = [:]

    func all() throws -> [Item] {
        Array(items.values)
    }

    func item(id: UUID) throws -> Item? {
        items[id]
    }

    func item(named name: String) throws -> Item? {
        let key = Item.nameKey(name)
        return items.values.first { $0.nameKey == key }
    }

    func save(_ item: Item) throws {
        items[item.id] = item
    }

    func delete(id: UUID) throws {
        items.removeValue(forKey: id)
    }
}

final class FakeKitRepository: KitRepository {
    var kits: [UUID: Kit] = [:]

    func all() throws -> [Kit] {
        Array(kits.values)
    }

    func kit(id: UUID) throws -> Kit? {
        kits[id]
    }

    func save(_ kit: Kit) throws {
        kits[kit.id] = kit
    }

    func delete(id: UUID) throws {
        kits.removeValue(forKey: id)
    }
}

final class FakeQuoteRepository: QuoteRepository {
    var quotes: [UUID: Quote] = [:]

    func all() throws -> [Quote] {
        Array(quotes.values)
    }

    func quote(id: UUID) throws -> Quote? {
        quotes[id]
    }

    func save(_ quote: Quote) throws {
        quotes[quote.id] = quote
    }

    func delete(id: UUID) throws {
        quotes.removeValue(forKey: id)
    }
}

final class FakeProfileRepository: ProfileRepository {
    var profile: BusinessProfile?

    func load() throws -> BusinessProfile? {
        profile
    }

    func save(_ profile: BusinessProfile) throws {
        self.profile = profile
    }
}

final class FakeAliasRepository: AliasRepository {
    var aliases: [UUID: [String]] = [:]

    func aliases(forItem itemID: UUID) throws -> [String] {
        aliases[itemID] ?? []
    }

    func add(alias: String, toItem itemID: UUID) throws {
        if aliases[itemID] == nil {
            aliases[itemID] = []
        }
        aliases[itemID]?.append(alias)
    }
}

struct FixedClock: Clock {
    let date: Date
    func now() -> Date { date }
}

struct FixedEntitlements: EntitlementProvider {
    let plan: Plan
    func currentPlan() -> Plan { plan }
}