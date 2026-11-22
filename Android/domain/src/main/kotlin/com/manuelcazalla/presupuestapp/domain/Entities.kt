package com.manuelcazalla.presupuestapp.domain

import java.math.BigDecimal

data class CatalogItem(
    val id: String,
    val name: String,
    val unit: String,
    val unitPrice: BigDecimal,
    val vatRate: BigDecimal?,
)

data class SavedQuote(
    val id: String,
    val number: String,
    val createdAtEpochMillis: Long,
    val clientName: String,
    val title: String,
    val status: String,
    val lines: List<QuoteLine>,
    val discount: Discount,
    val defaultVatRate: BigDecimal,
    val total: BigDecimal,
)
