import SwiftUI
import QuoteCore

/// S1 Onboarding: oficio, datos de empresa e IVA por defecto.
struct OnboardingView: View {
    @Bindable var viewModel: OnboardingViewModel
    let session: AppSession
    let router: AppRouter

    @State private var name = ""
    @State private var taxID = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var defaultVATRate = "21"
    @State private var terms = ""
    @State private var validityDays = "30"
    @State private var numberPrefix = "P"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(.tint)
                            .accessibilityHidden(true)
                        Text("onboarding.welcome")
                            .font(.title2.weight(.semibold))
                        Text("onboarding.welcome.message")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                    .accessibilityElement(children: .combine)
                }

                Section {
                    Picker("onboarding.selectTrade", selection: Binding(
                        get: { viewModel.trade },
                        set: { viewModel.selectTrade($0) }
                    )) {
                        Text("trade.plumber").tag(Trade.plumber)
                        Text("trade.mason").tag(Trade.mason)
                        Text("trade.electrician").tag(Trade.electrician)
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                } header: {
                    Text("onboarding.tradeSection")
                } footer: {
                    Text("onboarding.tradeFooter")
                }

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
                    Text("onboarding.businessSection")
                }

                Section {
                    TextField("field.defaultVAT", text: $defaultVATRate)
                        .keyboardType(.decimalPad)
                    TextField("field.validityDays", text: $validityDays)
                        .keyboardType(.numberPad)
                    TextField("field.numberPrefix", text: $numberPrefix)
                    TextField("field.terms", text: $terms, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("onboarding.defaultsSection")
                }

                if case .failed(let message) = viewModel.state {
                    Section {
                        Text(LocalizedStringKey(message))
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("onboarding.title")
            .navigationBarTitleDisplayMode(.large)
            .safeAreaInset(edge: .bottom) {
                Button {
                    save()
                } label: {
                    Text("onboarding.start")
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.bar)
                .accessibilityLabel("onboarding.start")
            }
        }
    }

    private func save() {
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
        if viewModel.state == .loaded {
            router.selectedTab = .prices
            session.completeOnboarding()
        }
    }
}
