import SwiftUI
import UIKit

/// S10 Ajustes: datos de empresa, IVA por defecto, condiciones y numeración.
struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    let makeWalkthroughViewModel: () -> OnboardingViewModel
    private let links = AppLinks.configured

    @Environment(AppRouter.self) private var router
    @Environment(\.openURL) private var openURL
    @State private var walkthroughPresentation: WalkthroughPresentation?
    @State private var isMailUnavailablePresented = false

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

            Section {
                Button {
                    presentWalkthrough()
                } label: {
                    Label("settings.howItWorks", systemImage: "questionmark.circle")
                }
                .accessibilityLabel(Text("settings.howItWorks"))

                if let mailtoURL = supportMailtoURL,
                   let supportEmail = links.supportEmail {
                    Button {
                        openURL(mailtoURL) { didOpen in
                            if !didOpen {
                                isMailUnavailablePresented = true
                            }
                        }
                    } label: {
                        Label("settings.contact", systemImage: "envelope")
                    }
                    .accessibilityLabel(Text("settings.contact"))
                    .accessibilityHint(Text("settings.contact.hint"))
                    .accessibilityIdentifier("settings.contact")
                    .accessibilityValue(Text(verbatim: supportEmail))
                }

                if let websiteURL = links.validWebsiteURL {
                    Link(destination: websiteURL) {
                        Label("settings.website", systemImage: "globe")
                    }
                    .accessibilityLabel(Text("settings.website"))
                    .accessibilityHint(Text("settings.opensBrowser"))
                }
            } header: {
                Text("settings.help.section")
            }

            Section {
                ShareLink(item: shareText) {
                    Label("settings.share", systemImage: "square.and.arrow.up")
                }
                .accessibilityLabel(Text("settings.share"))

                if let reviewURL = links.reviewURL {
                    Button {
                        openURL(reviewURL)
                    } label: {
                        Label("settings.rate", systemImage: "star")
                    }
                    .accessibilityLabel(Text("settings.rate"))
                    .accessibilityHint(Text("settings.opensBrowser"))
                }
            } header: {
                Text("settings.share.section")
            }

            Section {
                if let privacyURL = links.validPrivacyURL {
                    Link(destination: privacyURL) {
                        Label("settings.privacy", systemImage: "hand.raised")
                    }
                    .accessibilityLabel(Text("settings.privacy"))
                    .accessibilityHint(Text("settings.opensBrowser"))
                }

                if let termsURL = links.validTermsURL {
                    Link(destination: termsURL) {
                        Label("settings.terms", systemImage: "doc.text")
                    }
                    .accessibilityLabel(Text("settings.terms"))
                    .accessibilityHint(Text("settings.opensBrowser"))
                }
            } header: {
                Text("settings.legal.section")
            }

            Section {
                LabeledContent("settings.about.version") {
                    Text(versionDescription)
                        .accessibilityLabel(Text(verbatim: versionDescription))
                }
            } header: {
                Text("settings.about.section")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("settings.title")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $walkthroughPresentation) { presentation in
            OnboardingView(viewModel: presentation.viewModel, router: router)
        }
        .alert(
            "settings.contact.unavailable.title",
            isPresented: $isMailUnavailablePresented
        ) {
            Button("settings.contact.copyAddress") {
                if let supportEmail = links.supportEmail {
                    UIPasteboard.general.string = supportEmail
                }
            }
            Button("action.cancel", role: .cancel) {}
        } message: {
            Text("settings.contact.unavailable.message")
        }
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

    private func presentWalkthrough() {
        walkthroughPresentation = WalkthroughPresentation(
            viewModel: makeWalkthroughViewModel()
        )
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

    private var supportMailtoURL: URL? {
        links.supportMailtoURL(
            appVersion: appVersion,
            buildVersion: buildVersion,
            iosVersion: UIDevice.current.systemVersion
        )
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? String(localized: "settings.about.version.unknown")
    }

    private var buildVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
            ?? String(localized: "settings.about.version.unknown")
    }

    private var versionDescription: String {
        String.localizedStringWithFormat(
            String(localized: "settings.about.version.value"),
            appVersion,
            buildVersion
        )
    }

    private var shareText: String {
        links.shareText(
            appName: String(localized: "settings.appName"),
            phrase: String(localized: "settings.share.phrase")
        )
    }
}

private struct WalkthroughPresentation: Identifiable {
    let id = UUID()
    let viewModel: OnboardingViewModel
}
