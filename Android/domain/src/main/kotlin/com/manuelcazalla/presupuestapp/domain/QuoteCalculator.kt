package com.manuelcazalla.presupuestapp.domain

import java.math.BigDecimal
import java.math.MathContext
import java.math.RoundingMode
import java.util.TreeMap

data class QuoteLine(
    val quantity: BigDecimal,
    val unitPrice: BigDecimal,
    /** Percentage, e.g. 21 means 21%. */
    val vatRate: BigDecimal,
    val itemId: String? = null,
    val name: String = "",
    val unit: String = "ud",
)

sealed interface Discount {
    data object None : Discount
    data class Percent(val value: BigDecimal) : Discount
    data class Amount(val value: BigDecimal) : Discount
}

data class VatGroup(
    val rate: BigDecimal,
    val base: BigDecimal,
    val vat: BigDecimal,
)

data class QuoteTotals(
    val subtotal: BigDecimal,
    val discount: BigDecimal,
    val vatBreakdown: List<VatGroup>,
    val total: BigDecimal,
)

/** Pure Kotlin port of QuoteCore.QuoteCalculator. */
class QuoteCalculator {
    fun lineTotal(line: QuoteLine): BigDecimal = round2(line.quantity * line.unitPrice)

    fun calculate(lines: List<QuoteLine>, discount: Discount): QuoteTotals {
        val lineTotals = lines.map(::lineTotal)
        val subtotal = lineTotals.fold(BigDecimal.ZERO, BigDecimal::add)
        val discountAmount = discountAmount(discount, subtotal)

        val basesByRate = TreeMap<BigDecimal, BigDecimal>()
        lines.zip(lineTotals).forEach { (line, lineTotal) ->
            basesByRate.merge(line.vatRate, lineTotal, BigDecimal::add)
        }

        val rates = basesByRate.keys.toList()
        val sharesByRate = mutableMapOf<BigDecimal, BigDecimal>()
        var remainingDiscount = discountAmount
        rates.forEachIndexed { index, rate ->
            val grossBase = basesByRate.getValue(rate)
            val discountShare = when {
                index == rates.lastIndex -> remainingDiscount
                subtotal > BigDecimal.ZERO -> round2(
                    discountAmount.multiply(grossBase).divide(subtotal, MathContext.DECIMAL128),
                )
                else -> BigDecimal.ZERO
            }
            sharesByRate[rate] = discountShare
            remainingDiscount -= discountShare
        }

        val vatBreakdown = rates.map { rate ->
            val base = basesByRate.getValue(rate) - (sharesByRate[rate] ?: BigDecimal.ZERO)
            val vat = round2(base * rate / HUNDRED)
            VatGroup(rate = rate, base = base, vat = vat)
        }
        val total = vatBreakdown.fold(BigDecimal.ZERO) { sum, group -> sum + group.base + group.vat }

        return QuoteTotals(
            subtotal = subtotal,
            discount = discountAmount,
            vatBreakdown = vatBreakdown,
            total = total,
        )
    }

    fun discountAmount(discount: Discount, subtotal: BigDecimal): BigDecimal = when (discount) {
        Discount.None -> BigDecimal.ZERO
        is Discount.Percent -> minOf(round2(subtotal * discount.value / HUNDRED), subtotal)
        is Discount.Amount -> minOf(discount.value, subtotal)
    }

    private fun round2(value: BigDecimal): BigDecimal = value.setScale(2, RoundingMode.HALF_UP)

    private companion object {
        val HUNDRED = BigDecimal("100")
    }
}
