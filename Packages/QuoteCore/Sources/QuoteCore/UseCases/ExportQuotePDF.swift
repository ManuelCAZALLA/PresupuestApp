import Foundation

/// Genera el PDF de un presupuesto: el cálculo lo hace `QuoteCalculator`
/// y el dibujo el puerto `QuotePDFRenderer`. Marca de agua solo en plan gratuito.
public final class ExportQuotePDF {
    private let renderer: QuotePDFRenderer
    private let profile: ProfileRepository
    private let entitlements: EntitlementProvider
    private let calculator = QuoteCalculator()

    public init(
        renderer: QuotePDFRenderer,
        profile: ProfileRepository,
        entitlements: EntitlementProvider
    ) {
        self.renderer = renderer
        self.profile = profile
        self.entitlements = entitlements
    }

    public func execute(_ quote: Quote) throws -> URL {
        let business = try profile.load() ?? BusinessProfile()
        let totals = calculator.calculate(lines: quote.lines, discount: quote.discount)
        return try renderer.render(
            quote: quote,
            profile: business,
            totals: totals,
            watermark: entitlements.currentPlan() == .free
        )
    }
}
