import SwiftUI

/// Los tres caminos para cargar la tarifa, compartidos por el catálogo
/// vacío (S7) y el último paso del onboarding (S1).
struct TariffStartActions: View {
    let onImport: () -> Void
    let onPaste: () -> Void
    let onAddManually: () -> Void

    var body: some View {
        Button(action: onImport) {
            Label("catalog.empty.import", systemImage: "square.and.arrow.down")
                .frame(maxWidth: .infinity, minHeight: 56)
        }
        .buttonStyle(.borderedProminent)

        Button(action: onPaste) {
            Label("catalog.empty.paste", systemImage: "doc.on.clipboard")
                .frame(maxWidth: .infinity, minHeight: 56)
        }
        .buttonStyle(.bordered)

        Button(action: onAddManually) {
            Label("catalog.empty.addManual", systemImage: "plus")
                .frame(maxWidth: .infinity, minHeight: 56)
        }
        .buttonStyle(.bordered)
    }
}
