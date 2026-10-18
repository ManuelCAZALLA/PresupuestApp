import SwiftUI
import QuoteCore

/// S1 Onboarding: oficio, datos de empresa e IVA por defecto.
/// No siembra partidas: el catálogo arranca vacío (ver DECISIONS.md, D-007).
struct OnboardingView: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var name = ""
    @State private var taxID = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var defaultVATRate = "21"
    @State private var terms = ""
    @State private var validityDays = "30"
    @State private var numberPrefix = "P"

    var body: some View {
        Form {
            Section {
                Picker(
                    "onboarding.selectTrade",
                    selection: Binding(
                        get: { viewModel.trade },
                        set: { viewModel.selectTrade($0) }
                    )
                ) {
                    Text("trade.plumber").tag(Trade.plumber)
                    Text("trade.mason").tag(Trade.mason)
                    Text("trade.electrician").tag(Trade.electrician)
                }
            } header: {
                Text("onboarding.tradeSection")
            }

            Section {
                TextField("field.name", text: $name)
                TextField("field.taxID", text: $taxID)
                TextField("field.phone", text: $phone)
                TextField("field.email", text: $email)
                TextField("field.defaultVAT", text: $defaultVATRate)
                    .keyboardType(.decimalPad)
                TextField("field.validityDays", text: $validityDays)
                    .keyboardType(.numberPad)
                TextField("field.numberPrefix", text: $numberPrefix)
                TextField("field.terms", text: $terms)
            } header: {
                Text("onboarding.businessSection")
            }

            Section {
                Button("action.save") {
                    viewModel.updateProfile(
                        name: name,
                        taxID: taxID,
                        phone: phone,
                        email: email,
                        defaultVATRate: Decimal(
                            string: defaultVATRate.replacingOccurrences(of: ",", with: ".")
                        ) ?? Decimal(21),
                        terms: terms,
                        validityDays: Int(validityDays) ?? 30,
                        numberPrefix: numberPrefix
                    )
                    viewModel.save()
                }
                .buttonStyle(.borderedProminent)
            }

            if case .failed(let message) = viewModel.state {
                Section {
                    Text(LocalizedStringKey(message))
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("onboarding.title")
    }
}
