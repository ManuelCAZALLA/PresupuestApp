import Foundation

public final class NumberWords {
    public init() {}
    public func toNumber(_ token: String) -> Decimal? {
        switch token {
        case "un", "una", "uno": return Decimal(1)
        case "dos": return Decimal(2)
        case "tres": return Decimal(3)
        case "cuatro": return Decimal(4)
        case "cinco": return Decimal(5)
        case "seis": return Decimal(6)
        case "siete": return Decimal(7)
        case "ocho": return Decimal(8)
        case "nueve": return Decimal(9)
        case "diez": return Decimal(10)
        case "once": return Decimal(11)
        case "doce": return Decimal(12)
        case "trece": return Decimal(13)
        case "catorce": return Decimal(14)
        case "quince": return Decimal(15)
        case "dieciseis": return Decimal(16)
        case "diecisiete": return Decimal(17)
        case "dieciocho": return Decimal(18)
        case "diecinueve": return Decimal(19)
        case "veinte": return Decimal(20)
        case "veintiuno", "veintiun": return Decimal(21)
        case "veintidos": return Decimal(22)
        case "veintitres": return Decimal(23)
        case "veinticuatro": return Decimal(24)
        case "veinticinco": return Decimal(25)
        case "veintiseis": return Decimal(26)
        case "veintisiete": return Decimal(27)
        case "veintiocho": return Decimal(28)
        case "veintinueve": return Decimal(29)
        case "treinta": return Decimal(30)
        case "cuarenta": return Decimal(40)
        case "cincuenta": return Decimal(50)
        case "sesenta": return Decimal(60)
        case "setenta": return Decimal(70)
        case "ochenta": return Decimal(80)
        case "noventa": return Decimal(90)
        default: return nil
        }
    }
}
