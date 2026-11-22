package com.manuelcazalla.presupuestapp.data

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(tableName = "business_profile")
data class BusinessProfileRecord(
    @PrimaryKey val id: Int = 1,
    val name: String,
    val phone: String,
    val taxId: String,
    val defaultVatRate: String,
    val hasCompletedOnboarding: Boolean,
)

@Entity(tableName = "catalog_items")
data class CatalogItemRecord(
    @PrimaryKey val id: String,
    val name: String,
    val unit: String,
    /** Decimal text preserves the exact price; never store money as SQLite REAL. */
    val unitPrice: String,
    val vatRate: String?,
)

@Entity(tableName = "quotes")
data class QuoteRecord(
    @PrimaryKey val id: String,
    val number: String,
    val createdAtEpochMillis: Long,
    val clientName: String,
    val title: String,
    val status: String,
    val discountType: String,
    val discountValue: String,
    val defaultVatRate: String,
    val total: String,
)

@Entity(
    tableName = "quote_lines",
    foreignKeys = [ForeignKey(
        entity = QuoteRecord::class,
        parentColumns = ["id"],
        childColumns = ["quoteId"],
        onDelete = ForeignKey.CASCADE,
    )],
    indices = [Index("quoteId")],
)
data class QuoteLineRecord(
    @PrimaryKey val id: String,
    val quoteId: String,
    val itemId: String?,
    val name: String,
    val unit: String,
    val quantity: String,
    val unitPrice: String,
    val vatRate: String,
)
