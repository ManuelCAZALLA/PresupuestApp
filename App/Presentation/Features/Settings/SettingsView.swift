import SwiftUI

/// S10 Ajustes: datos de empresa, IVA por defecto, condiciones y numeración.
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
                    .textContentType(.organizationName)
                TextField("field.taxID", text: $taxID)
                TextField("field.phone", text: $phone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                TextField("field.email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
            } header: {
                Text("settings.businessSection")
            }

            Section {
                TextField("field.defaultVAT", text: $defaultVATRate)
                    .keyboardType(.decimalPad)
                TextField("field.validityDays", text: $validityDays)
                    .keyboardType(.numberPad)
                TextField("field.numberPrefix", text: $numberPrefix)
                TextField("field.terms", text: $terms, axis: .vertical)
                    .lineLimit(3...8)
            } header: {
                Text("settings.defaultsSection")
            } footer: {
                Text("settings.defaultsFooter")
            }

            Section {
                Button {
                    save()
                } label: {
                    Text("action.save")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if viewModel.saved {
                    Label("settings.saved", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                if case .failed(let message) = viewModel.state {
                    Text(LocalizedStringKey(message))
                        .foregroundStyle(.red)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("settings.title")
        .navigationBarTitleDisplayMode(.large)
        .task { viewModel.load() }
        .onChange(of: viewModel.state) { _, newState in
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

    private func save() {
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
}
