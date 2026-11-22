package com.manuelcazalla.presupuestapp.domain

interface CatalogRepository {
    suspend fun all(): List<CatalogItem>
    suspend fun save(item: CatalogItem)
    suspend fun delete(id: String)
}

interface QuoteRepository {
    suspend fun all(): List<SavedQuote>
    suspend fun quote(id: String): SavedQuote?
    suspend fun save(quote: SavedQuote)
}

interface BusinessProfileRepository {
    suspend fun load(): BusinessProfile
    suspend fun save(profile: BusinessProfile)
}
