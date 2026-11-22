package com.manuelcazalla.presupuestapp.data

import androidx.room.Dao
import androidx.room.Database
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.RoomDatabase
import androidx.room.Transaction

@Dao
interface CatalogItemDao {
    @Query("SELECT * FROM catalog_items ORDER BY name COLLATE NOCASE")
    suspend fun all(): List<CatalogItemRecord>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun save(item: CatalogItemRecord)

    @Query("DELETE FROM catalog_items WHERE id = :id")
    suspend fun delete(id: String)
}

@Dao
interface QuoteDao {
    @Query("SELECT * FROM quotes ORDER BY createdAtEpochMillis DESC")
    suspend fun all(): List<QuoteRecord>

    @Query("SELECT * FROM quotes WHERE id = :id LIMIT 1")
    suspend fun quote(id: String): QuoteRecord?

    @Query("SELECT * FROM quote_lines WHERE quoteId = :quoteId ORDER BY rowid")
    suspend fun lines(quoteId: String): List<QuoteLineRecord>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun save(quote: QuoteRecord)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun saveLines(lines: List<QuoteLineRecord>)

    @Query("DELETE FROM quote_lines WHERE quoteId = :quoteId")
    suspend fun deleteLines(quoteId: String)

    @Transaction
    suspend fun replace(quote: QuoteRecord, lines: List<QuoteLineRecord>) {
        save(quote)
        deleteLines(quote.id)
        if (lines.isNotEmpty()) saveLines(lines)
    }
}

@Database(
    entities = [CatalogItemRecord::class, QuoteRecord::class, QuoteLineRecord::class],
    version = 1,
    exportSchema = false,
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun catalogItems(): CatalogItemDao
    abstract fun quotes(): QuoteDao
}
