import SwiftUI

/// S8 ImportTariff. Pantalla pendiente de M4: aquí vivirán los lectores
/// de Excel/CSV, el pegado de texto, la asignación de columnas y la
/// revisión antes de guardar, además de la plantilla Excel descargable
/// (columnas Nombre, Unidad y Precio); ver docs/PRODUCT.md, docs/ROADMAP.md
/// y la skill catalog-import.
///
/// De momento solo informa: la app no trae partidas y el usuario puede
/// añadirlas a mano mientras tanto.
struct ImportTariffView: View {
    var body: some View {
        ContentUnavailableView {
            Label("importTariff.pending.title", systemImage: "doc.badge.arrow.up")
        } description: {
            Text("importTariff.pending.message")
        }
        .navigationTitle("importTariff.title")
    }
}

#Preview {
    NavigationStack {
        ImportTariffView()
    }
}
