import Foundation
import Testing
@testable import QuoteCore

// Los helpers `d(_:)` y `makeUTCDate` vienen de Fakes.swift (compartidos en el target).

struct UseCaseTests {
    private func makeQuote(lines: [QuoteLine] = []) -> Quote {
        Quote(
            id: UUID(),
            number: "P-2026-0001",
            date: makeUTCDate(2026, 1, 1),
            validityDays: 30,
            client: Client(),
            status: .draft,
            lines: lines,
            discount: .none,
            notes: "",
            defaultVATRate: d("21")
        )
    }

    private func makeLine(unit: MeasureUnit = .unit, vatRate: Decimal = d("21")) -> QuoteLine {
        QuoteLine(
            itemID: nil,
            name: "Item",
            unit: unit,
            quantity: d("1"),
            unitPrice: d("10.00"),
            vatRate: vatRate,
            origin: .manual
        )
    }

    private func makeProfile() -> BusinessProfile {
        BusinessProfile(name: "T", taxID: "T", phone: "T", email: "T", defaultVATRate: d("21"), terms: "", validityDays: 30, numberPrefix: "P")
    }

    // Numeración: <prefijo>-<año>-<secuencia de 4 dígitos>; la secuencia reinicia cada año
    @Test func createQuoteNumbering() throws {
        let clock = FixedClock(date: makeUTCDate(2026, 3, 15))
        let quotesRepo = FakeQuoteRepository()
        let profileRepo = FakeProfileRepository()
        profileRepo.profile = makeProfile()
        let entitlements = FixedEntitlements(plan: .free)
        let create = CreateQuote(quotes: quotesRepo, profile: profileRepo, clock: clock, entitlements: entitlements)

        let q1 = try create.execute(client: Client(name: "A"))
        #expect(q1.number == "P-2026-0001")
        #expect(q1.status == .draft)
        #expect(q1.lines.isEmpty)
        #expect(q1.defaultVATRate == d("21"))
        #expect(q1.date == clock.now())

        let q2 = try create.execute(client: Client(name: "B"))
        #expect(q2.number == "P-2026-0002")

        // Año distinto: la secuencia reinicia
        let clock2027 = FixedClock(date: makeUTCDate(2027, 1, 1))
        let create2027 = CreateQuote(quotes: quotesRepo, profile: profileRepo, clock: clock2027, entitlements: entitlements)
        let q3 = try create2027.execute(client: Client(name: "C"))
        #expect(q3.number == "P-2027-0001")
    }

    // Límite gratuito: 5 presupuestos por mes natural; Plan Pro sin límite
    @Test func quotaEnforcedForFreePlan() throws {
        let clock = FixedClock(date: makeUTCDate(2026, 3, 15))
        let quotesRepo = FakeQuoteRepository()
        let profileRepo = FakeProfileRepository()
        profileRepo.profile = makeProfile()
        let entitlementsFree = FixedEntitlements(plan: .free)
        let create = CreateQuote(quotes: quotesRepo, profile: profileRepo, clock: clock, entitlements: entitlementsFree)

        // 5 presupuestos en el mes
        for _ in 0..<5 {
            _ = try create.execute(client: Client())
        }
        // El 6º supera la cuota
        #expect(throws: DomainError.quotaExceeded) {
            _ = try create.execute(client: Client())
        }

        // Plan Pro: sin límite
        let quotesRepo2 = FakeQuoteRepository()
        let createPro = CreateQuote(quotes: quotesRepo2, profile: profileRepo, clock: clock, entitlements: FixedEntitlements(plan: .pro))
        for _ in 0..<5 {
            _ = try createPro.execute(client: Client())
        }
        let q6 = try createPro.execute(client: Client())
        #expect(q6.number == "P-2026-0006")
        #expect(quotesRepo2.quotes.count == 6)
    }

    // El contador de la cuota se reinicia al cambiar de mes natural
    @Test func quotaResetsOnNewMonth() throws {
        let clockMarch = FixedClock(date: makeUTCDate(2026, 3, 15))
        let quotesRepo = FakeQuoteRepository()
        let profileRepo = FakeProfileRepository()
        profileRepo.profile = makeProfile()
        let entitlements = FixedEntitlements(plan: .free)
        let createMarch = CreateQuote(quotes: quotesRepo, profile: profileRepo, clock: clockMarch, entitlements: entitlements)

        // 5 en marzo; el 6º lanza quotaExceeded
        for _ in 0..<5 {
            _ = try createMarch.execute(client: Client())
        }
        #expect(throws: DomainError.quotaExceeded) {
            _ = try createMarch.execute(client: Client())
        }

        // Abril: cuota reiniciada
        let clockApril = FixedClock(date: makeUTCDate(2026, 4, 1))
        let checkApril = CheckQuota(quotes: quotesRepo, clock: clockApril, entitlements: entitlements)
        let statusApril = try checkApril.execute()
        #expect(statusApril.used == 0)
        #expect(statusApril.remaining == 5)
        #expect(statusApril.canCreate == true)

        let createApril = CreateQuote(quotes: quotesRepo, profile: profileRepo, clock: clockApril, entitlements: entitlements)
        let q6 = try createApril.execute(client: Client(name: "F"))
        #expect(q6.number == "P-2026-0006") // misma secuencia anual, cuota reiniciada
    }

    // Duplicar: copia líneas (con unidad y tipo de IVA), descuento, notas, IVA por defecto y cliente; número nuevo, fecha de hoy, draft
    @Test func duplicateQuoteCopiesLinesAndResetsState() throws {
        let clock = FixedClock(date: makeUTCDate(2026, 3, 15))
        let quotesRepo = FakeQuoteRepository()
        let profileRepo = FakeProfileRepository()
        profileRepo.profile = makeProfile()
        let duplicate = DuplicateQuote(quotes: quotesRepo, profile: profileRepo, clock: clock)

        let original = Quote(
            id: UUID(),
            number: "P-2026-0001",
            date: makeUTCDate(2026, 1, 1),
            validityDays: 30,
            client: Client(name: "Client"),
            status: .sent,
            lines: [makeLine(unit: .meter, vatRate: d("10"))],
            discount: .percent(d("10")),
            notes: "note",
            defaultVATRate: d("21")
        )
        quotesRepo.save(original)

        let dup = try duplicate.execute(original)
        #expect(dup.id != original.id)
        #expect(dup.number == "P-2026-0002") // número nuevo: siguiente de la secuencia anual
        #expect(dup.date == clock.now())
        #expect(dup.status == .draft)
        // Líneas tal cual: nombre, cantidad, precio, unidad y tipo de IVA
        #expect(dup.lines.count == original.lines.count)
        #expect(dup.lines[0].name == original.lines[0].name)
        #expect(dup.lines[0].quantity == original.lines[0].quantity)
        #expect(dup.lines[0].unitPrice == original.lines[0].unitPrice)
        #expect(dup.lines[0].unit == .meter)
        #expect(dup.lines[0].vatRate == d("10"))
        // Descuento, notas, IVA por defecto y datos del cliente
        #expect(dup.discount == .percent(d("10")))
        #expect(dup.notes == "note")
        #expect(dup.defaultVATRate == d("21"))
        #expect(dup.client.name == original.client.name)
    }

    // Estados: draft → sent; sent → accepted | rejected | draft. accepted y rejected son terminales
    @Test func changeQuoteStatusTransitions() throws {
        let quotesRepo = FakeQuoteRepository()
        let changeStatus = ChangeQuoteStatus(quotes: quotesRepo)

        let withLines = makeQuote(lines: [makeLine()])
        quotesRepo.save(withLines)

        // draft → sent ok
        _ = try changeStatus.execute(withLines, to: .sent)
        #expect(quotesRepo.quotes[withLines.id]?.status == .sent) // el repositorio queda actualizado

        // sent → accepted ok
        var sent = withLines
        sent.status = .sent
        _ = try changeStatus.execute(sent, to: .accepted)
        #expect(quotesRepo.quotes[withLines.id]?.status == .accepted)

        // sent → rejected ok
        sent = withLines
        sent.status = .sent
        _ = try changeStatus.execute(sent, to: .rejected)
        #expect(quotesRepo.quotes[withLines.id]?.status == .rejected)

        // sent → draft ok (un enviado se puede volver a editar)
        sent = withLines
        sent.status = .sent
        _ = try changeStatus.execute(sent, to: .draft)
        #expect(quotesRepo.quotes[withLines.id]?.status == .draft)

        // Transiciones inválidas: draft solo va a sent
        #expect(throws: DomainError.invalidTransition(from: .draft, to: .accepted)) {
            _ = try changeStatus.execute(withLines, to: .accepted)
        }
        #expect(throws: DomainError.invalidTransition(from: .draft, to: .rejected)) {
            _ = try changeStatus.execute(withLines, to: .rejected)
        }
        // accepted y rejected son estados terminales
        var accepted = withLines
        accepted.status = .accepted
        #expect(throws: DomainError.invalidTransition(from: .accepted, to: .sent)) {
            _ = try changeStatus.execute(accepted, to: .sent)
        }
        var rejected = withLines
        rejected.status = .rejected
        #expect(throws: DomainError.invalidTransition(from: .rejected, to: .draft)) {
            _ = try changeStatus.execute(rejected, to: .draft)
        }
    }

    // CheckQuota: used / limit / remaining / canCreate; Pro con límite nulo
    @Test func checkQuotaStatus() throws {
        let clock = FixedClock(date: makeUTCDate(2026, 3, 15))
        let quotesRepo = FakeQuoteRepository()
        let profileRepo = FakeProfileRepository()
        profileRepo.profile = makeProfile()
        let entitlementsFree = FixedEntitlements(plan: .free)
        let create = CreateQuote(quotes: quotesRepo, profile: profileRepo, clock: clock, entitlements: entitlementsFree)
        let check = CheckQuota(quotes: quotesRepo, clock: clock, entitlements: entitlementsFree)

        // 0 usados; crear 2
        _ = try create.execute(client: Client())
        _ = try create.execute(client: Client())
        let status2 = try check.execute()
        #expect(status2.plan == .free)
        #expect(status2.used == 2)
        #expect(status2.limit == 5)
        #expect(status2.remaining == 3)
        #expect(status2.canCreate == true)

        // Llenar el mes (5)
        _ = try create.execute(client: Client())
        _ = try create.execute(client: Client())
        _ = try create.execute(client: Client())
        let status5 = try check.execute()
        #expect(status5.used == 5)
        #expect(status5.remaining == 0)
        #expect(status5.canCreate == false)

        // Pro: límite nulo
        let quotesRepo2 = FakeQuoteRepository()
        let checkPro = CheckQuota(quotes: quotesRepo2, clock: clock, entitlements: FixedEntitlements(plan: .pro))
        let statusPro = try checkPro.execute()
        #expect(statusPro.plan == .pro)
        #expect(statusPro.limit == nil)
        #expect(statusPro.canCreate == true)
    }
}
