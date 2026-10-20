import PhotosUI
import SwiftUI
import UIKit

/// Paso 4: datos del negocio (el nombre es obligatorio; teléfono, NIF y
/// logo son opcionales) e IVA por defecto.
struct OnboardingBusinessView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                CardSurface {
                    VStack(alignment: .leading, spacing: 14) {
                        OnboardingField(labelKey: "field.name") {
                            TextField("field.name", text: $viewModel.name)
                                .textContentType(.organizationName)
                        }
                        Divider()
                        OnboardingField(labelKey: "field.taxID") {
                            TextField("field.taxID", text: $viewModel.taxID)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                        }
                        Divider()
                        OnboardingField(labelKey: "field.phone") {
                            TextField("field.phone", text: $viewModel.phone)
                                .keyboardType(.phonePad)
                                .textContentType(.telephoneNumber)
                        }
                        Divider()
                        logoRow
                    }
                }

                vatCard

                if case .failed(let message) = viewModel.state {
                    Label(LocalizedStringKey(message), systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .onChange(of: photoItem) { _, item in
            loadLogo(from: item)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("onboarding.title")
                .font(.largeTitle.weight(.bold))
            Text("onboarding.business.subtitle")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
    }

    private var logoRow: some View {
        // La clave se resuelve fuera del cierre de PhotosPicker, que es
        // `@Sendable` y no puede leer el estado del ViewModel.
        let actionKey = viewModel.logo == nil ? "onboarding.logo.add" : "onboarding.logo.change"

        return HStack(spacing: 14) {
            logoPreview

            PhotosPicker(selection: $photoItem, matching: .images) {
                Text(LocalizedStringKey(actionKey))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(BrandPalette.accent)
                    .frame(minHeight: 44, alignment: .leading)
            }

            if viewModel.logo != nil {
                Button("onboarding.logo.remove") {
                    viewModel.setLogo(nil)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(minHeight: 44)
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var logoPreview: some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        if let data = viewModel.logo, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(shape)
                .overlay(shape.strokeBorder(BrandPalette.border, lineWidth: 1))
                .accessibilityHidden(true)
        } else {
            shape
                .fill(BrandPalette.card)
                .overlay(shape.strokeBorder(BrandPalette.border, lineWidth: 1))
                .overlay {
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 56, height: 56)
                .accessibilityHidden(true)
        }
    }

    private var vatCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 14) {
                Text("onboarding.vat.title")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                Picker("onboarding.vat.title", selection: $viewModel.vatChoice) {
                    Text("onboarding.vat.standard").tag(OnboardingViewModel.VATChoice.standard)
                    Text("onboarding.vat.reduced").tag(OnboardingViewModel.VATChoice.reduced)
                    Text("onboarding.vat.other").tag(OnboardingViewModel.VATChoice.other)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .accessibilityLabel("onboarding.vat.title")

                if viewModel.vatChoice == .other {
                    TextField("field.defaultVAT", text: $viewModel.otherVATRateText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("field.defaultVAT")
                }

                if viewModel.isOtherVATRateInvalid {
                    Label("onboarding.vat.invalid", systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(BrandPalette.warning)
                }

                Text("onboarding.vat.note")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func loadLogo(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            let data = try? await item.loadTransferable(type: Data.self)
            viewModel.setLogo(data)
        }
    }
}

/// Etiqueta encima del campo, con el campo como elemento de VoiceOver.
private struct OnboardingField<Content: View>: View {
    let labelKey: LocalizedStringKey
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(labelKey)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            content
                .font(.body)
                .accessibilityLabel(labelKey)
        }
    }
}
