import SwiftUI
import UIKit

extension View {
    /// Limita el ancho del contenido y lo centra en pantallas grandes.
    /// En iPhone no cambia nada porque la pantalla ya es más estrecha.
    func readableContentWidth(_ maxWidth: CGFloat = 720) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }

    /// Mantiene el botón a un ancho cómodo y centrado, con el fondo de la
    /// barra ocupando todo el ancho disponible.
    func centeredActionWidth(_ maxWidth: CGFloat = 560) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }

    /// En iPhone conserva los detents de siempre. En iPad deja que el sistema
    /// presente la hoja centrada en lugar de ocupar toda la pantalla.
    @ViewBuilder
    func adaptiveSheetDetents(_ detents: Set<PresentationDetent> = [.large]) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self
        } else {
            presentationDetents(detents)
        }
    }

    /// En iPad usa una hoja de página para recorridos completos; en iPhone
    /// mantiene la presentación normal.
    @ViewBuilder
    func adaptivePageSheet() -> some View {
        if #available(iOS 18.0, *), UIDevice.current.userInterfaceIdiom == .pad {
            presentationSizing(.page)
        } else {
            self
        }
    }
}
