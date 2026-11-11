import QuoteCore
import Testing
@testable import PresupuestApp

@Suite("Configuración de la versión 1.0")
struct ReleaseConfigurationTests {
    @Test("La app se publica sin límite de presupuestos")
    func defaultPlanIsUnlimited() {
        #expect(StubEntitlements().currentPlan() == .pro)
    }
}
