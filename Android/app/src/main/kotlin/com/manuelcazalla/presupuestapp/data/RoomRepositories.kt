package com.manuelcazalla.presupuestapp.data

import com.manuelcazalla.presupuestapp.domain.CatalogItem
import com.manuelcazalla.presupuestapp.domain.CatalogRepository
import com.manuelcazalla.presupuestapp.domain.Discount
import com.manuelcazalla.presupuestapp.domain.QuoteLine
import com.manuelcazalla.presupuestapp.domain.QuoteRepository
import com.manuelcazalla.presupuestapp.domain.SavedQuote
import java.math.BigDecimal

class RoomCatalogRepository(private val dao: CatalogItemDao) : CatalogRepository {
    override suspend fun all(): List<CatalogItem> = dao.all().map { record ->
        CatalogItem(
            id = record.id,
            name = record.name,
            unit = record.unit,
            unitPrice = record.unitPrice.toBigDecimal(),
            vatRate = record.vatRate?.toBigDecimal(),
        )
    }

    override suspend fun save(item: CatalogItem) {
        dao.save(
            CatalogItemRecord(
                id = item.id,
                name = item.name,
                unit = item.unit,
                unitPrice = item.unitPrice.toPlainString(),
                vatRate = item.vatRate?.toPlainString(),
            ),
        )
    }

    override suspend fun delete(id: String) = dao.delete(id)
}

class RoomQuoteRepository(private val dao: QuoteDao) : QuoteRepository {
    override suspend fun all(): List<SavedQuote> = dao.all().map { record -> load(record) }

    override suspend fun quote(id: String): SavedQuote? = dao.quote(id)?.let { load(it) }

    override suspend fun save(quote: SavedQuote) {
        val (discountType, discountValue) = when (val discount = quote.discount) {
            Discount.None -> "none" to "0"
            is Discount.Percent -> "percent" to discount.value.toPlainString()
            is Discount.Amount -> "amount" to discount.value.toPlainString()
        }
        val record = QuoteRecord(
            id = quote.id,
            number = quote.number,
            createdAtEpochMillis = quote.createdAtEpochMillis,
            clientName = quote.clientName,
            title = quote.title,
            status = quote.status,
            discountType = discountType,
            discountValue = discountValue,
            defaultVatRate = quote.defaultVatRate.toPlainString(),
            total = quote.total.toPlainString(),
        )
        val lines = quote.lines.mapIndexed { index, line ->
            QuoteLineRecord(
                id = "${quote.id}-$index",
                quoteId = quote.id,
                itemId = line.itemId,
                name = line.name,
                unit = line.unit,
                quantity = line.quantity.toPlainString(),
                unitPrice = line.unitPrice.toPlainString(),
                vatRate = line.vatRate.toPlainString(),
            )
        }
        dao.replace(record, lines)
    }

    private suspend fun load(record: QuoteRecord): SavedQuote {
        val discount = when (record.discountType) {
            "percent" -> Discount.Percent(record.discountValue.toBigDecimal())
            "amount" -> Discount.Amount(record.discountValue.toBigDecimal())
            else -> Discount.None
        }
        val lines = dao.lines(record.id).map { line ->
            QuoteLine(
                quantity = line.quantity.toBigDecimal(),
                unitPrice = line.unitPrice.toBigDecimal(),
                vatRate = line.vatRate.toBigDecimal(),
                itemId = line.itemId,
                name = line.name,
                unit = line.unit,
            )
        }
        return SavedQuote(
            id = record.id,
            number = record.number,
            createdAtEpochMillis = record.createdAtEpochMillis,
            clientName = record.clientName,
            title = record.title,
            status = record.status,
            lines = lines,
            discount = discount,
            defaultVatRate = record.defaultVatRate.toBigDecimal(),
            total = record.total.toBigDecimal(),
        )
    }
}
