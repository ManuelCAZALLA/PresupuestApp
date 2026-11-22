package com.manuelcazalla.presupuestapp.domain

import java.math.BigDecimal
import kotlin.test.Test
import kotlin.test.assertEquals

class QuoteCalculatorVectorsTest {
    @Test
    fun sharedIosVectorsMatchExactly() {
        val calculator = QuoteCalculator()
        val vectors = javaClass.classLoader
            ?.getResourceAsStream("quote_calculator_vectors.tsv")
            ?.bufferedReader()
            ?.useLines { lines ->
                lines.filter { it.isNotBlank() && !it.startsWith("#") }
                    .map(::parseVector)
                    .toList()
            }
            ?: error("Missing shared quote_calculator_vectors.tsv fixture")

        assertEquals(11, vectors.size)
        vectors.forEach { vector ->
            val totals = calculator.calculate(vector.lines, vector.discount)
            assertDecimal(vector.subtotal, totals.subtotal, "${vector.name}: subtotal")
            assertDecimal(vector.discountAmount, totals.discount, "${vector.name}: discount")
            assertDecimal(vector.total, totals.total, "${vector.name}: total")
            assertEquals(vector.expectedLines.size, vector.lines.size, "${vector.name}: line count")
            vector.lines.zip(vector.expectedLines).forEachIndexed { index, (line, expected) ->
                assertDecimal(expected, calculator.lineTotal(line), "${vector.name}: line ${index + 1}")
            }
            assertEquals(vector.vatGroups.size, totals.vatBreakdown.size, "${vector.name}: VAT group count")
            vector.vatGroups.zip(totals.vatBreakdown).forEachIndexed { index, (expected, actual) ->
                assertDecimal(expected.rate, actual.rate, "${vector.name}: VAT rate ${index + 1}")
                assertDecimal(expected.base, actual.base, "${vector.name}: VAT base ${index + 1}")
                assertDecimal(expected.vat, actual.vat, "${vector.name}: VAT amount ${index + 1}")
            }
        }
    }

    private fun parseVector(row: String): Vector {
        val fields = row.split('|')
        require(fields.size == 7) { "Invalid fixture row: $row" }
        val lines = fields[1].split(';').map { values ->
            val parts = values.split(',')
            QuoteLine(
                quantity = parts[0].decimal(),
                unitPrice = parts[1].decimal(),
                vatRate = parts[2].decimal(),
            )
        }
        val expectedLines = fields[1].split(';').map { values -> values.split(',')[3].decimal() }
        val discountParts = fields[2].split(':', limit = 2)
        val discount = when (discountParts[0]) {
            "none" -> Discount.None
            "percent" -> Discount.Percent(discountParts[1].decimal())
            "amount" -> Discount.Amount(discountParts[1].decimal())
            else -> error("Unknown discount in fixture row: $row")
        }
        val vatGroups = if (fields[5].isEmpty()) emptyList() else fields[5].split(';').map { values ->
            val parts = values.split(',')
            VatExpectation(parts[0].decimal(), parts[1].decimal(), parts[2].decimal())
        }
        return Vector(
            name = fields[0],
            lines = lines,
            expectedLines = expectedLines,
            discount = discount,
            subtotal = fields[3].decimal(),
            discountAmount = fields[4].decimal(),
            vatGroups = vatGroups,
            total = fields[6].decimal(),
        )
    }

    private fun String.decimal(): BigDecimal = toBigDecimal()

    private fun assertDecimal(expected: BigDecimal, actual: BigDecimal, message: String) {
        assertEquals(0, expected.compareTo(actual), message)
    }

    private data class Vector(
        val name: String,
        val lines: List<QuoteLine>,
        val expectedLines: List<BigDecimal>,
        val discount: Discount,
        val subtotal: BigDecimal,
        val discountAmount: BigDecimal,
        val vatGroups: List<VatExpectation>,
        val total: BigDecimal,
    )

    private data class VatExpectation(
        val rate: BigDecimal,
        val base: BigDecimal,
        val vat: BigDecimal,
    )
}
