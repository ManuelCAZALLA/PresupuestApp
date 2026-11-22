package com.manuelcazalla.presupuestapp

import android.app.Application
import android.content.Intent
import android.graphics.Paint
import android.graphics.pdf.PdfDocument
import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.core.content.FileProvider
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.room.Room
import com.manuelcazalla.presupuestapp.data.AppDatabase
import com.manuelcazalla.presupuestapp.data.RoomCatalogRepository
import com.manuelcazalla.presupuestapp.data.RoomQuoteRepository
import com.manuelcazalla.presupuestapp.domain.CatalogItem
import com.manuelcazalla.presupuestapp.domain.Discount
import com.manuelcazalla.presupuestapp.domain.QuoteCalculator
import com.manuelcazalla.presupuestapp.domain.QuoteLine
import com.manuelcazalla.presupuestapp.domain.SavedQuote
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.io.File
import java.math.BigDecimal
import java.text.NumberFormat
import java.util.Locale
import java.util.UUID

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { MaterialTheme { QuoteApp() } }
    }
}

internal class AppContainer(application: Application) {
    private val database = Room.databaseBuilder(application, AppDatabase::class.java, "presupuestapp.db").build()
    val catalog = RoomCatalogRepository(database.catalogItems())
    val quotes = RoomQuoteRepository(database.quotes())
}

class PresupuestApplication : Application() {
    internal val container by lazy { AppContainer(this) }
}

data class HomeState(
    val items: List<CatalogItem> = emptyList(),
    val quotes: List<SavedQuote> = emptyList(),
    val notice: String? = null,
)

class HomeViewModel(application: Application) : AndroidViewModel(application) {
    private val container = (application as PresupuestApplication).container
    private val _state = MutableStateFlow(HomeState())
    val state = _state.asStateFlow()
    private val calculator = QuoteCalculator()

    init { refresh() }

    fun refresh() = viewModelScope.launch {
        _state.value = _state.value.copy(items = container.catalog.all(), quotes = container.quotes.all())
    }

    fun saveItem(name: String, unit: String, price: String, vat: String) = viewModelScope.launch {
        val parsedPrice = price.toDecimalOrNull()
        val parsedVat = vat.toDecimalOrNull()
        if (name.isBlank() || parsedPrice == null || parsedPrice < BigDecimal.ZERO || (vat.isNotBlank() && (parsedVat == null || parsedVat < BigDecimal.ZERO))) {
            _state.value = _state.value.copy(notice = "Revisa el nombre, el precio y el IVA.")
            return@launch
        }
        container.catalog.save(CatalogItem(UUID.randomUUID().toString(), name.trim(), unit.ifBlank { "ud" }, parsedPrice, parsedVat))
        _state.value = _state.value.copy(notice = "Precio guardado.")
        refresh()
    }

    fun deleteItem(id: String) = viewModelScope.launch { container.catalog.delete(id); refresh() }

    fun createQuote(client: String, title: String, selected: Map<String, String>, vat: String, discountPercent: String) = viewModelScope.launch {
        val vatRate = vat.toDecimalOrNull()
        val discountValue = discountPercent.toDecimalOrNull() ?: BigDecimal.ZERO
        val lines = _state.value.items.mapNotNull { item ->
            val quantity = selected[item.id]?.toDecimalOrNull()
            if (quantity == null || quantity <= BigDecimal.ZERO) null else QuoteLine(
                quantity = quantity, unitPrice = item.unitPrice, vatRate = item.vatRate ?: vatRate ?: BigDecimal("21"),
                itemId = item.id, name = item.name, unit = item.unit,
            )
        }
        if (lines.isEmpty() || vatRate == null || vatRate < BigDecimal.ZERO || discountValue < BigDecimal.ZERO) {
            _state.value = _state.value.copy(notice = "Añade alguna línea y revisa el IVA y el descuento.")
            return@launch
        }
        val discount = if (discountValue == BigDecimal.ZERO) Discount.None else Discount.Percent(discountValue)
        val totals = calculator.calculate(lines, discount)
        val id = UUID.randomUUID().toString()
        val quote = SavedQuote(
            id = id, number = "P-${System.currentTimeMillis()}", createdAtEpochMillis = System.currentTimeMillis(),
            clientName = client.trim(), title = title.trim().ifBlank { "Presupuesto" }, status = "Borrador",
            lines = lines, discount = discount, defaultVatRate = vatRate, total = totals.total,
        )
        container.quotes.save(quote)
        _state.value = _state.value.copy(notice = "Presupuesto guardado.")
        refresh()
    }

    fun dismissNotice() { _state.value = _state.value.copy(notice = null) }
}

@Composable
private fun QuoteApp(vm: HomeViewModel = viewModel()) {
    val state by vm.state.collectAsState()
    var tab by remember { mutableStateOf(0) }
    var showItemForm by remember { mutableStateOf(false) }
    var showQuoteForm by remember { mutableStateOf(false) }
    Scaffold { padding ->
        Column(Modifier.fillMaxSize().padding(padding).padding(horizontal = 20.dp, vertical = 16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(stringResource(R.string.app_name), style = MaterialTheme.typography.headlineMedium)
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedButton(onClick = { tab = 0 }) { Text("Presupuestos") }
                OutlinedButton(onClick = { tab = 1 }) { Text("Mi tarifa") }
            }
            if (tab == 0) {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text("Presupuestos", style = MaterialTheme.typography.titleLarge)
                    Button(onClick = { showQuoteForm = true }, enabled = state.items.isNotEmpty()) { Text("Nuevo") }
                }
                if (state.quotes.isEmpty()) Text("Todavía no hay presupuestos. Añade precios a tu tarifa y crea el primero.")
                LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(state.quotes, key = { it.id }) { quote -> QuoteCard(quote) }
                }
            } else {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text("Mi tarifa", style = MaterialTheme.typography.titleLarge)
                    Button(onClick = { showItemForm = true }) { Text("Añadir precio") }
                }
                if (state.items.isEmpty()) Text("Tu tarifa está vacía. Añade tus conceptos y precios.")
                LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(state.items, key = { it.id }) { item ->
                        Card(Modifier.fillMaxWidth()) {
                            Row(Modifier.fillMaxWidth().padding(16.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                                Column(Modifier.weight(1f)) {
                                    Text(item.name, style = MaterialTheme.typography.titleMedium)
                                    Text("${money(item.unitPrice)} / ${item.unit} · IVA ${item.vatRate?.let { "${it}%" } ?: "del presupuesto"}")
                                }
                                TextButton(onClick = { vm.deleteItem(item.id) }) { Text("Borrar") }
                            }
                        }
                    }
                }
            }
        }
    }
    if (showItemForm) ItemDialog(onDismiss = { showItemForm = false }, onSave = { n,u,p,v -> vm.saveItem(n,u,p,v); showItemForm = false })
    if (showQuoteForm) QuoteDialog(items = state.items, onDismiss = { showQuoteForm = false }, onSave = { c,t,s,v,d -> vm.createQuote(c,t,s,v,d); showQuoteForm = false })
    state.notice?.let { message -> AlertDialog(onDismissRequest = vm::dismissNotice, title = { Text("PresupuestApp") }, text = { Text(message) }, confirmButton = { TextButton(onClick = vm::dismissNotice) { Text("Aceptar") } }) }
}

@Composable
private fun ItemDialog(onDismiss: () -> Unit, onSave: (String, String, String, String) -> Unit) {
    var name by remember { mutableStateOf("") }; var unit by remember { mutableStateOf("ud") }
    var price by remember { mutableStateOf("") }; var vat by remember { mutableStateOf("") }
    AlertDialog(onDismissRequest = onDismiss, title = { Text("Añadir a mi tarifa") }, text = {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(name, { name = it }, label = { Text("Concepto") })
            OutlinedTextField(unit, { unit = it }, label = { Text("Unidad") })
            OutlinedTextField(price, { price = it }, label = { Text("Precio sin IVA (€)") })
            OutlinedTextField(vat, { vat = it }, label = { Text("IVA (%) · opcional") })
        }
    }, confirmButton = { Button(onClick = { onSave(name, unit, price, vat) }) { Text("Guardar") } }, dismissButton = { TextButton(onClick = onDismiss) { Text("Cancelar") } })
}

@Composable
private fun QuoteDialog(items: List<CatalogItem>, onDismiss: () -> Unit, onSave: (String, String, Map<String, String>, String, String) -> Unit) {
    var client by remember { mutableStateOf("") }; var title by remember { mutableStateOf("") }
    var vat by remember { mutableStateOf("21") }; var discount by remember { mutableStateOf("0") }
    val quantities = remember { mutableStateOf(items.associate { it.id to "" }) }
    AlertDialog(onDismissRequest = onDismiss, title = { Text("Nuevo presupuesto") }, text = {
        LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            item { OutlinedTextField(client, { client = it }, label = { Text("Cliente · opcional") }) }
            item { OutlinedTextField(title, { title = it }, label = { Text("Trabajo") }) }
            item { OutlinedTextField(vat, { vat = it }, label = { Text("IVA por defecto (%)") }) }
            item { OutlinedTextField(discount, { discount = it }, label = { Text("Descuento (%)") }) }
            items(items, key = { it.id }) { item ->
                OutlinedTextField(
                    value = quantities.value[item.id].orEmpty(),
                    onValueChange = { quantities.value = quantities.value + (item.id to it) },
                    label = { Text("${item.name} · ${money(item.unitPrice)} / ${item.unit}") },
                )
            }
        }
    }, confirmButton = { Button(onClick = { onSave(client, title, quantities.value, vat, discount) }) { Text("Guardar") } }, dismissButton = { TextButton(onClick = onDismiss) { Text("Cancelar") } })
}

@Composable
private fun QuoteCard(quote: SavedQuote) {
    val context = LocalContext.current
    Card(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(quote.title, style = MaterialTheme.typography.titleMedium)
            Text("${quote.number} · ${quote.clientName.ifBlank { "Sin cliente" }}")
            Text("${quote.lines.size} líneas · ${money(quote.total)}")
            OutlinedButton(onClick = { sharePdf(context, quote) }) { Text("Compartir PDF") }
        }
    }
}

private fun sharePdf(context: android.content.Context, quote: SavedQuote) {
    val document = PdfDocument()
    val totals = QuoteCalculator().calculate(quote.lines, quote.discount)
    val page = document.startPage(PdfDocument.PageInfo.Builder(595, 842, 1).create())
    val paint = Paint().apply { textSize = 14f }
    var y = 56
    page.canvas.drawText("PRESUPUESTO ${quote.number}", 40f, y.toFloat(), paint); y += 28
    page.canvas.drawText(quote.title, 40f, y.toFloat(), paint); y += 22
    if (quote.clientName.isNotBlank()) { page.canvas.drawText("Cliente: ${quote.clientName}", 40f, y.toFloat(), paint); y += 24 }
    quote.lines.forEach { line ->
        page.canvas.drawText("${line.quantity.stripTrailingZeros().toPlainString()} ${line.unit}  ${line.name}", 40f, y.toFloat(), paint)
        y += 22
    }
    y += 18
    page.canvas.drawText("Subtotal: ${money(totals.subtotal)}", 40f, y.toFloat(), paint); y += 22
    if (totals.discount > BigDecimal.ZERO) {
        page.canvas.drawText("Descuento: −${money(totals.discount)}", 40f, y.toFloat(), paint); y += 22
    }
    totals.vatBreakdown.forEach { group ->
        page.canvas.drawText("Base IVA ${group.rate}%: ${money(group.base)}  ·  Cuota: ${money(group.vat)}", 40f, y.toFloat(), paint)
        y += 22
    }
    y += 8
    page.canvas.drawText("Total: ${money(quote.total)}", 40f, y.toFloat(), paint)
    document.finishPage(page)
    val file = File(context.cacheDir, "presupuesto-${quote.number}.pdf")
    file.outputStream().use(document::writeTo)
    document.close()
    val uri: Uri = FileProvider.getUriForFile(context, "${context.packageName}.files", file)
    context.startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).apply {
        type = "application/pdf"; putExtra(Intent.EXTRA_STREAM, uri); addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }, "Compartir presupuesto"))
}

private fun String.toDecimalOrNull(): BigDecimal? = trim().replace(',', '.').takeIf { it.isNotEmpty() }?.toBigDecimalOrNull()
private fun money(value: BigDecimal): String = NumberFormat.getCurrencyInstance(Locale.forLanguageTag("es-ES")).format(value)
