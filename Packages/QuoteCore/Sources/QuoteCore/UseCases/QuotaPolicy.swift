import Foundation

/// Cuota gratuita: 5 presupuestos creados por mes natural (ver docs/DOMAIN.md).
public enum QuotaPolicy {
    public static let freeMonthlyLimit = 5

    /// Número de presupuestos creados en el mismo mes natural que `date`.
    public static func quotesCreated(inMonthOf date: Date, quotes: [Quote]) -> Int {
        let calendar = Calendar.current
        return quotes.filter { calendar.isDate($0.date, equalTo: date, toGranularity: .month) }.count
    }
}
