package com.manuelcazalla.presupuestapp.domain

class ListCatalogItems(private val catalog: CatalogRepository) {
    suspend fun execute(): List<CatalogItem> = catalog.all()
}

class SaveCatalogItem(private val catalog: CatalogRepository) {
    suspend fun execute(item: CatalogItem) = catalog.save(item)
}

class DeleteCatalogItem(private val catalog: CatalogRepository) {
    suspend fun execute(id: String) = catalog.delete(id)
}

class ListSavedQuotes(private val quotes: QuoteRepository) {
    suspend fun execute(): List<SavedQuote> = quotes.all()
}

class LoadSavedQuote(private val quotes: QuoteRepository) {
    suspend fun execute(id: String): SavedQuote? = quotes.quote(id)
}

class SaveQuote(private val quotes: QuoteRepository) {
    suspend fun execute(quote: SavedQuote) = quotes.save(quote)
}
