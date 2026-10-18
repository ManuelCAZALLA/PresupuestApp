import Foundation
import Testing
@testable import QuoteCore

// Los helpers `d(_:)` y `makeUTCDate` vienen de Fakes.swift (compartidos en el target).

struct CatalogUseCaseTests {
    private func makeItem(name: String = "Item") -> Item {
        Item(
            name: name,
            aliases: ["alias"],
            unit: .unit,
            unitPrice: d("10.00"),
            kind: .material,
            category: "Categoría",
            trade: .plumber
        )
    }

    // SaveBusinessProfile / LoadBusinessProfile: ida y vuelta por el repositorio
    @Test func businessProfileRoundTrip() throws {
        let repo = FakeProfileRepository()
        let save = SaveBusinessProfile(profile: repo)
        let load = LoadBusinessProfile(profile: repo)
        #expect(try load.execute() == nil)

        let profile = BusinessProfile(
            name: "Taller",
            taxID: "T",
            phone: "1",
            email: "e",
            defaultVATRate: d("21"),
            terms: "condiciones",
            validityDays: 30,
            numberPrefix: "P"
        )
        try save.execute(profile)
        #expect(try load.execute() == profile)
    }

    // ManageItems: crear, editar y borrar; ListItems: listar
    @Test func manageItemsCreateUpdateDelete() throws {
        let repo = FakeItemRepository()
        let manage = ManageItems(items: repo)
        let list = ListItems(items: repo)
        #expect(try list.execute().isEmpty)

        let item = makeItem()
        try manage.execute(.create(item))
        #expect(try list.execute().count == 1)

        var edited = item
        edited.unitPrice = d("20.00")
        try manage.execute(.update(edited))
        #expect(try repo.item(id: item.id)?.unitPrice == d("20.00"))

        try manage.execute(.delete(item.id))
        #expect(try list.execute().isEmpty)
    }

    // Guardar dos veces la misma partida (mismo nombre normalizado) no duplica:
    // la segunda creación actualiza la existente.
    @Test func creatingSameItemTwiceDoesNotDuplicate() throws {
        let repo = FakeItemRepository()
        let manage = ManageItems(items: repo)
        let list = ListItems(items: repo)

        try manage.execute(.create(makeItem(name: "Urinario")))
        try manage.execute(.create(makeItem(name: "  urinario ")))

        let all = try list.execute()
        #expect(all.count == 1)
        #expect(all.first?.name == "  urinario ")
    }

    // La clave de emparejamiento ignora mayúsculas y tildes (y colapsa espacios).
    @Test func nameKeyIgnoresCaseAndAccents() {
        #expect(Item.nameKey("Sifón  de Lavabo") == Item.nameKey("sifon de lavabo"))
        #expect(Item.nameKey("Instalación") == "instalacion")
        #expect(Item.nameKey("  Tubo   de   Cobre ") == "tubo de cobre")
        #expect(Item.nameKey("Termo Eléctrico") == "termo electrico")
    }

    // LoadTradePack: crea partidas SIN precio (el usuario los pone)
    @Test func loadTradePackCreatesItemsWithoutPrices() throws {
        struct FakePackLoader: TradePackLoading {
            let pack: TradePackData
            func load(trade: Trade) throws -> TradePackData { pack }
        }
        let pack = TradePackData(
            trade: .plumber,
            entries: [
                TradePackEntry(
                    name: "Urinario",
                    unit: .unit,
                    kind: .material,
                    category: "Sanitarios",
                    aliases: ["urinarios"]
                )
            ]
        )
        let load = LoadTradePack(loader: FakePackLoader(pack: pack))

        let items = try load.execute(trade: .plumber)
        #expect(items.count == 1)
        #expect(items[0].name == "Urinario")
        #expect(items[0].trade == .plumber)
        #expect(items[0].unit == .unit)
        #expect(items[0].kind == .material)
        #expect(items[0].category == "Sanitarios")
        #expect(items[0].aliases == ["urinarios"])
        #expect(items[0].unitPrice == d("0")) // sin precio: lo pone el usuario
    }
}
