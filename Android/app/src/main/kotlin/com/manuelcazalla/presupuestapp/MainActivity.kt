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
import androidx.compose.material3.FilterChip
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
import com.manuelcazalla.presupuestapp.data.MIGRATION_1_2
import com.manuelcazalla.presupuestapp.data.RoomBusinessProfileRepository
import com.manuelcazalla.presupuestapp.data.RoomCatalogRepository
import com.manuelcazalla.presupuestapp.data.RoomQuoteRepository
import com.manuelcazalla.presupuestapp.domain.CatalogItem
import com.manuelcazalla.presupuestapp.domain.BusinessProfile
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
    private val database = Room.databaseBuilder(application, AppDatabase::class.java, "presupuestapp.db")
        .addMigrations(MIGRATION_1_2)
        .build()
    val catalog = RoomCatalogRepository(database.catalogItems())
    val quotes = RoomQuoteRepository(database.quotes())
    val profile = RoomBusinessProfileRepository(database.businessProfile())
}

class PresupuestApplication : Application() {
    internal val container by lazy { AppContainer(this) }
}

data class HomeState(
    val items: List<CatalogItem> = emptyList(),
    val quotes: List<SavedQuote> = emptyList(),
    val notice: String? = null,
    val profile: BusinessProfile = BusinessProfile(),
    val profileLoaded: Boolean = false,
)

class HomeViewModel(application: Application) : AndroidViewModel(application) {
    private val container = (application as PresupuestApplication).container
    private val _state = MutableStateFlow(HomeState())
    val state = _state.asStateFlow()
    private val calculator = QuoteCalculator()

    init { refresh() }

    fun refresh() = viewModelScope.launch {
        _state.value = _state.value.copy(items = container.catalog.all(), quotes = container.quotes.all(), profile = container.profile.load(), profileLoaded = true)
    }

    fun saveProfile(name: String, phone: String, taxId: String, vat: String) = viewModelScope.launch {
        val rate = vat.toDecimalOrNull()
        if (name.isBlank() || rate == null || rate < BigDecimal.ZERO) {
            _state.value = _state.value.copy(notice = "Escribe el nombre del negocio y un IVA válido.")
            return@launch
        }
        val profile = BusinessProfile(name.trim(), phone.trim(), taxId.trim(), rate, true)
        container.profile.save(profile)
        _state.value = _state.value.copy(profile = profile)
    }

    fun saveItem(id: String?, name: String, unit: String, price: String, vat: String) = viewModelScope.launch {
        val parsedPrice = price.toDecimalOrNull()
        val parsedVat = vat.toDecimalOrNull()
        if (name.isBlank() || parsedPrice == null || parsedPrice < BigDecimal.ZERO || (vat.isNotBlank() && (parsedVat == null || parsedVat < BigDecimal.ZERO))) {
            _state.value = _state.value.copy(notice = "Revisa el nombre, el precio y el IVA.")
            return@launch
        }
        container.catalog.save(CatalogItem(id ?: UUID.randomUUID().toString(), name.trim(), unit.ifBlank { "ud" }, parsedPrice, parsedVat))
        _state.value = _state.value.copy(notice = if (id == null) "Precio guardado." else "Precio actualizado.")
        refresh()
    }

    fun deleteItem(id: String) = viewModelScope.launch { container.catalog.delete(id); refresh() }

    fun createQuote(client: String, title: String, selected: Map<String, String>, vat: String, discountValueText: String, discountIsFixedAmount: Boolean) = viewModelScope.launch {
        val vatRate = vat.toDecimalOrNull()
        val discountValue = discountValueText.toDecimalOrNull()
        val lines = _state.value.items.mapNotNull { item ->
            val quantity = selected[item.id]?.toDecimalOrNull()
            if (quantity == null || quantity <= BigDecimal.ZERO) null else QuoteLine(
                quantity = quantity, unitPrice = item.unitPrice, vatRate = item.vatRate ?: vatRate ?: _state.value.profile.defaultVatRate,
                itemId = item.id, name = item.name, unit = item.unit,
            )
        }
        if (lines.isEmpty() || vatRate == null || vatRate < BigDecimal.ZERO || discountValue == null || discountValue < BigDecimal.ZERO) {
            _state.value = _state.value.copy(notice = "Añade alguna línea y revisa el IVA y el descuento.")
            return@launch
        }
        val discount = when {
            discountValue == BigDecimal.ZERO -> Discount.None
            discountIsFixedAmount -> Discount.Amount(discountValue)
            else -> Discount.Percent(discountValue)
        }
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

    fun updateQuote(quote: SavedQuote, client: String, title: String, selected: Map<String, String>, vat: String, discountValueText: String, discountIsFixedAmount: Boolean) = viewModelScope.launch {
        val vatRate = vat.toDecimalOrNull()
        val discountValue = discountValueText.toDecimalOrNull()
        if (vatRate == null || vatRate < BigDecimal.ZERO || discountValue == null || discountValue < BigDecimal.ZERO) {
            _state.value = _state.value.copy(notice = "Revisa el IVA y el descuento.")
            return@launch
        }
        val existingByItem = quote.lines.mapNotNull { line -> line.itemId?.let { it to line } }.toMap()
        val selectedLines = _state.value.items.mapNotNull { item ->
            val quantity = selected[item.id]?.toDecimalOrNull()
            if (quantity == null || quantity <= BigDecimal.ZERO) null else {
                val snapshot = existingByItem[item.id]
                if (snapshot != null) snapshot.copy(quantity = quantity)
                else QuoteLine(quantity, item.unitPrice, item.vatRate ?: vatRate, item.id, item.name, item.unit)
            }
        }
        val removedFromCatalog = quote.lines.filter { line -> line.itemId == null || _state.value.items.none { it.id == line.itemId } }
        val lines = selectedLines + removedFromCatalog
        if (lines.isEmpty()) {
            _state.value = _state.value.copy(notice = "Añade alguna línea al presupuesto.")
            return@launch
        }
        val discount = when {
            discountValue == BigDecimal.ZERO -> Discount.None
            discountIsFixedAmount -> Discount.Amount(discountValue)
            else -> Discount.Percent(discountValue)
        }
        val updated = quote.copy(
            clientName = client.trim(),
            title = title.trim().ifBlank { "Presupuesto" },
            lines = lines,
            discount = discount,
            defaultVatRate = vatRate,
            total = calculator.calculate(lines, discount).total,
        )
        container.quotes.save(updated)
        _state.value = _state.value.copy(notice = "Presupuesto actualizado.")
        refresh()
    }

    fun dismissNotice() { _state.value = _state.value.copy(notice = null) }
}

@Composable
private fun QuoteApp(vm: HomeViewModel = viewModel()) {
    val state by vm.state.collectAsState()
    var tab by remember { mutableStateOf(0) }
    var showItemForm by remember { mutableStateOf(false) }
    var itemBeingEdited by remember { mutableStateOf<CatalogItem?>(null) }
    var showQuoteForm by remember { mutableStateOf(false) }
    var quoteBeingEdited by remember { mutableStateOf<SavedQuote?>(null) }
    var showProfile by remember { mutableStateOf(false) }
    var showIntro by remember { mutableStateOf(false) }
    var introDismissed by remember { mutableStateOf(false) }
    Scaffold { padding ->
        Column(Modifier.fillMaxSize().padding(padding).padding(horizontal = 20.dp, vertical = 16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(stringResource(R.string.app_name), style = MaterialTheme.typography.headlineMedium)
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text(state.profile.name)
                Row {
                    TextButton(onClick = { showIntro = true }) { Text("Cómo funciona") }
                    TextButton(onClick = { showProfile = true }) { Text("Mi negocio") }
                }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedButton(onClick = { tab = 0 }) { Text("Presupuestos") }
                OutlinedButton(onClick = { tab = 1 }) { Text("Mi tarifa") }
            }
            if (tab == 0) {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text("Presupuestos", style = MaterialTheme.typography.titleLarge)
                    Button(onClick = { quoteBeingEdited = null; showQuoteForm = true }, enabled = state.items.isNotEmpty()) { Text("Nuevo") }
                }
                if (state.quotes.isEmpty()) Text("Todavía no hay presupuestos. Añade precios a tu tarifa y crea el primero.")
                LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(state.quotes, key = { it.id }) { quote ->
                        QuoteCard(quote, onEdit = { quoteBeingEdited = quote; showQuoteForm = true })
                    }
                }
            } else {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text("Mi tarifa", style = MaterialTheme.typography.titleLarge)
                    Button(onClick = { itemBeingEdited = null; showItemForm = true }) { Text("Añadir precio") }
                }
                if (state.items.isEmpty()) Text("Tu tarifa está vacía. Añade tus conceptos y precios.")
                LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(state.items, key = { it.id }) { item ->
                        Card(onClick = { itemBeingEdited = item; showItemForm = true }, modifier = Modifier.fillMaxWidth()) {
                            Row(Modifier.fillMaxWidth().padding(16.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                                Column(Modifier.weight(1f)) {
                                    Text(item.name, style = MaterialTheme.typography.titleMedium)
                                    Text("${money(item.unitPrice)} / ${item.unit} · IVA ${item.vatRate?.let { "${it}%" } ?: "del presupuesto"}")
                                }
                                Row {
                                    TextButton(onClick = { itemBeingEdited = item; showItemForm = true }) { Text("Editar") }
                                    TextButton(onClick = { vm.deleteItem(item.id) }) { Text("Borrar") }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    if (showItemForm) ItemDialog(
        item = itemBeingEdited,
        onDismiss = { showItemForm = false; itemBeingEdited = null },
        onSave = { id, n, u, p, v -> vm.saveItem(id, n, u, p, v); showItemForm = false; itemBeingEdited = null },
    )
    if (showQuoteForm) QuoteDialog(
        items = state.items,
        defaultVatRate = state.profile.defaultVatRate,
        quote = quoteBeingEdited,
        onDismiss = { showQuoteForm = false; quoteBeingEdited = null },
        onSave = { quote, c, t, s, v, d, fixed ->
            if (quote == null) vm.createQuote(c, t, s, v, d, fixed)
            else vm.updateQuote(quote, c, t, s, v, d, fixed)
            showQuoteForm = false
            quoteBeingEdited = null
        },
    )
    state.notice?.let { message -> AlertDialog(onDismissRequest = vm::dismissNotice, title = { Text("PresupuestApp") }, text = { Text(message) }, confirmButton = { TextButton(onClick = vm::dismissNotice) { Text("Aceptar") } }) }
    val shouldShowIntro = state.profileLoaded && (!introDismissed && !state.profile.hasCompletedOnboarding || showIntro) && !showProfile
    val shouldShowRequiredProfile = state.profileLoaded && !state.profile.hasCompletedOnboarding && introDismissed
    if (shouldShowIntro) {
        OnboardingIntroDialog(
            onSkip = { introDismissed = true; showIntro = false },
            onFinish = { introDismissed = true; showIntro = false },
        )
    }
    if (shouldShowRequiredProfile || (state.profileLoaded && state.profile.hasCompletedOnboarding && showProfile)) {
        ProfileDialog(state.profile, shouldShowRequiredProfile, { showProfile = false }, vm::saveProfile)
    }
}

private data class OnboardingSlide(val title: String, val body: String)

@Composable
private fun OnboardingIntroDialog(onSkip: () -> Unit, onFinish: () -> Unit) {
    val slides = listOf(
        OnboardingSlide("Tu tarifa, siempre a mano", "Importa tus precios desde Excel, CSV o una lista. Solo una vez. Tus datos se quedan en tu móvil."),
        OnboardingSlide("Presupuesta en minutos", "Añade los trabajos que pide el cliente y el total se calcula con tus precios y tu IVA."),
        OnboardingSlide("Envíalo como un profesional", "Genera un PDF con los datos de tu negocio y compártelo por WhatsApp o correo."),
    )
    var page by remember { mutableStateOf(0) }
    AlertDialog(
        onDismissRequest = onSkip,
        title = {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text("Cómo funciona")
                TextButton(onClick = onSkip) { Text("Saltar") }
            }
        },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                Text("${page + 1} de ${slides.size}", style = MaterialTheme.typography.labelMedium)
                Text(slides[page].title, style = MaterialTheme.typography.titleLarge)
                Text(slides[page].body, style = MaterialTheme.typography.bodyLarge)
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    slides.indices.forEach { index ->
                        Text(if (index == page) "●" else "○", color = MaterialTheme.colorScheme.primary)
                    }
                }
            }
        },
        confirmButton = {
            Button(onClick = { if (page == slides.lastIndex) onFinish() else page += 1 }) {
                Text(if (page == slides.lastIndex) "Empezar" else "Siguiente")
            }
        },
    )
}

@Composable
private fun ProfileDialog(initial: BusinessProfile, required: Boolean, onDismiss: () -> Unit, onSave: (String, String, String, String) -> Unit) {
    var name by remember(initial) { mutableStateOf(initial.name) }
    var phone by remember(initial) { mutableStateOf(initial.phone) }
    var taxId by remember(initial) { mutableStateOf(initial.taxId) }
    var vat by remember(initial) { mutableStateOf(initial.defaultVatRate.stripTrailingZeros().toPlainString()) }
    AlertDialog(
        onDismissRequest = { if (!required) onDismiss() },
        title = { Text(if (required) "Tu negocio" else "Datos del negocio") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                if (required) Text("Estos datos aparecerán en tus presupuestos. Se guardan solo en este dispositivo.")
                OutlinedTextField(name, { name = it }, label = { Text("Nombre del negocio *") }, singleLine = true)
                OutlinedTextField(phone, { phone = it }, label = { Text("Teléfono · opcional") }, singleLine = true)
                OutlinedTextField(taxId, { taxId = it }, label = { Text("NIF · opcional") }, singleLine = true)
                OutlinedTextField(vat, { vat = it }, label = { Text("IVA por defecto (%)") }, singleLine = true)
            }
        },
        confirmButton = { Button(onClick = { onSave(name, phone, taxId, vat) }, enabled = name.isNotBlank()) { Text("Guardar") } },
        dismissButton = { if (!required) TextButton(onClick = onDismiss) { Text("Cancelar") } },
    )
}

@Composable
private fun ItemDialog(item: CatalogItem?, onDismiss: () -> Unit, onSave: (String?, String, String, String, String) -> Unit) {
    var name by remember(item?.id) { mutableStateOf(item?.name.orEmpty()) }; var unit by remember(item?.id) { mutableStateOf(item?.unit ?: "ud") }
    var price by remember(item?.id) { mutableStateOf(item?.unitPrice?.stripTrailingZeros()?.toPlainString().orEmpty()) }
    var vat by remember(item?.id) { mutableStateOf(item?.vatRate?.stripTrailingZeros()?.toPlainString().orEmpty()) }
    AlertDialog(onDismissRequest = onDismiss, title = { Text(if (item == null) "Añadir a mi tarifa" else "Editar precio") }, text = {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(name, { name = it }, label = { Text("Concepto") })
            OutlinedTextField(unit, { unit = it }, label = { Text("Unidad") })
            OutlinedTextField(price, { price = it }, label = { Text("Precio sin IVA (€)") })
            OutlinedTextField(vat, { vat = it }, label = { Text("IVA (%) · opcional") })
        }
    }, confirmButton = { Button(onClick = { onSave(item?.id, name, unit, price, vat) }) { Text("Guardar") } }, dismissButton = { TextButton(onClick = onDismiss) { Text("Cancelar") } })
}

@Composable
private fun QuoteDialog(items: List<CatalogItem>, defaultVatRate: BigDecimal, quote: SavedQuote?, onDismiss: () -> Unit, onSave: (SavedQuote?, String, String, Map<String, String>, String, String, Boolean) -> Unit) {
    var client by remember(quote?.id) { mutableStateOf(quote?.clientName.orEmpty()) }; var title by remember(quote?.id) { mutableStateOf(quote?.title.orEmpty()) }
    var vat by remember(quote?.id, defaultVatRate) { mutableStateOf((quote?.defaultVatRate ?: defaultVatRate).stripTrailingZeros().toPlainString()) }
    var discount by remember(quote?.id) {
        mutableStateOf(when (val value = quote?.discount) {
            is Discount.Percent -> value.value.stripTrailingZeros().toPlainString()
            is Discount.Amount -> value.value.stripTrailingZeros().toPlainString()
            else -> "0"
        })
    }
    var discountIsFixedAmount by remember(quote?.id) { mutableStateOf(quote?.discount is Discount.Amount) }
    val quantities = remember(quote?.id, items) {
        mutableStateOf(items.associate { item ->
            item.id to (quote?.lines?.firstOrNull { it.itemId == item.id }?.quantity?.stripTrailingZeros()?.toPlainString().orEmpty())
        })
    }
    AlertDialog(onDismissRequest = onDismiss, title = { Text(if (quote == null) "Nuevo presupuesto" else "Editar presupuesto") }, text = {
        LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            item { OutlinedTextField(client, { client = it }, label = { Text("Cliente · opcional") }) }
            item { OutlinedTextField(title, { title = it }, label = { Text("Trabajo") }) }
            item { OutlinedTextField(vat, { vat = it }, label = { Text("IVA por defecto (%)") }) }
            item {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilterChip(selected = !discountIsFixedAmount, onClick = { discountIsFixedAmount = false }, label = { Text("Porcentaje") })
                    FilterChip(selected = discountIsFixedAmount, onClick = { discountIsFixedAmount = true }, label = { Text("Importe (€)") })
                }
            }
            item { OutlinedTextField(discount, { discount = it }, label = { Text(if (discountIsFixedAmount) "Descuento (€)" else "Descuento (%)") }) }
            items(items, key = { it.id }) { item ->
                Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    TextButton(onClick = {
                        val current = quantities.value[item.id]?.toDecimalOrNull() ?: BigDecimal.ZERO
                        val next = (current - BigDecimal.ONE).max(BigDecimal.ZERO)
                        quantities.value = quantities.value + (item.id to if (next == BigDecimal.ZERO) "" else next.stripTrailingZeros().toPlainString())
                    }) { Text("−") }
                    OutlinedTextField(
                        modifier = Modifier.weight(1f),
                        value = quantities.value[item.id].orEmpty(),
                        onValueChange = { quantities.value = quantities.value + (item.id to it) },
                        label = { Text("${item.name} · ${money(item.unitPrice)} / ${item.unit}") },
                    )
                    TextButton(onClick = {
                        val current = quantities.value[item.id]?.toDecimalOrNull() ?: BigDecimal.ZERO
                        quantities.value = quantities.value + (item.id to (current + BigDecimal.ONE).stripTrailingZeros().toPlainString())
                    }) { Text("+") }
                }
            }
        }
    }, confirmButton = { Button(onClick = { onSave(quote, client, title, quantities.value, vat, discount, discountIsFixedAmount) }) { Text("Guardar") } }, dismissButton = { TextButton(onClick = onDismiss) { Text("Cancelar") } })
}

@Composable
private fun QuoteCard(quote: SavedQuote, onEdit: () -> Unit) {
    val context = LocalContext.current
    Card(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(quote.title, style = MaterialTheme.typography.titleMedium)
            Text("${quote.number} · ${quote.clientName.ifBlank { "Sin cliente" }}")
            Text("${quote.lines.size} líneas · ${money(quote.total)}")
            TextButton(onClick = onEdit) { Text("Editar presupuesto") }
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
