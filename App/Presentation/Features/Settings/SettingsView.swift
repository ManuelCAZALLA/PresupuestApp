import SwiftUI

/// S10 Ajustes: datos de empresa, IVA por defecto,
/// condiciones, validez y numeración.
struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    @State private var name = ""
    @State private var taxID = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var defaultVATRate = ""
    @State private var terms = ""
    @State private var validityDays = ""
    @State private var numberPrefix = ""

    var body: some View {
        Form {
            Section {
                TextField("field.name", text: $name)
                TextField("field.taxID", text: $taxID)
                TextField("field.phone", text: $phone)
                TextField("field.email", text: $email)
            } header: {
                Text("settings.businessSection")
            }

            Section {
                TextField("field.defaultVAT", text: $defaultVATRate)
                    .keyboardType(.decimalPad)
                TextField("field.validityDays", text: $validityDays)
                    .keyboardType(.numberPad)
                TextField("field.numberPrefix", text: $numberPrefix)
                TextField("field.terms", text: $terms)
            } header: {
                Text("settings.defaultsSection")
            }

            Section {
                Button("action.save") {
                    viewModel.update(
                        name: name,
                        taxID: taxID,
                        phone: phone,
                        email: email,
                        defaultVATRate: Decimal(
                            string: defaultVATRate.replacingOccurrences(of: ",", with: ".")
                        ) ?? Decimal(0),
                        terms: terms,
                        validityDays: Int(validityDays) ?? 30,
                        numberPrefix: numberPrefix
                    )
                    viewModel.save()
                }
                .buttonStyle(.borderedProminent)

                if viewModel.saved {
                    Label("settings.saved", systemImage: "checkmark.circle")
                        .foregroundStyle(.green)
                }

                if case .failed(let message) = viewModel.state {
                    Text(LocalizedStringKey(message))
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("settings.title")
        .task {
            viewModel.load()
        }
        .onChange(of: viewModel.state) { _, newState in
            // Rellena los campos con el perfil cargado.
            if case .loaded = newState, !viewModel.saved {
                name = viewModel.profile.name
                taxID = viewModel.profile.taxID
                phone = viewModel.profile.phone
                email = viewModel.profile.email
                terms = viewModel.profile.terms
                validityDays = "\(viewModel.profile.validityDays)"
                numberPrefix = viewModel.profile.numberPrefix
                defaultVATRate = CurrencyFormatter.plainString(
                    from: viewModel.profile.defaultVATRate
                )
            }
        }
    }
}
