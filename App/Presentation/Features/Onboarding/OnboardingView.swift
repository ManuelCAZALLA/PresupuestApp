import SwiftUI

/// S1 Onboarding: carrusel de tres pasos, datos del negocio y el catálogo
/// vacío. La misma vista sirve para el paseo de Ajustes → "Cómo funciona",
/// que solo muestra los pasos 1–3 y no marca la bandera (D-016).
struct OnboardingView: View {
    @Bindable var viewModel: OnboardingViewModel
    let router: AppRouter

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            topBar
            content
            footer
        }
        .background(BrandPalette.background.ignoresSafeArea())
    }

    // MARK: - Barra superior

    private var topBar: some View {
        HStack {
            if !viewModel.isFirstStep {
                Button {
                    animate { viewModel.back() }
                } label: {
                    Label("onboarding.back", systemImage: "chevron.left")
                        .labelStyle(.titleAndIcon)
                        .font(.body.weight(.semibold))
                        .frame(minHeight: 44)
                }
                .accessibilityHint("onboarding.back.hint")
            }
            Spacer(minLength: 0)
            if viewModel.showsSkip {
                Button("onboarding.skip") {
                    animate { viewModel.skip() }
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(BrandPalette.accent)
                .frame(minHeight: 44)
            }
        }
        .frame(maxWidth: 640)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .frame(minHeight: 44)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Contenido

    private var content: some View {
        ZStack {
            switch viewModel.step {
            case .tariff:
                OnboardingCarouselPage(
                    illustration: .tariff,
                    titleKey: "onboarding.page1.title",
                    bodyKey: "onboarding.page1.body",
                    noteKey: "onboarding.page1.note"
                )
            case .estimate:
                OnboardingCarouselPage(
                    illustration: .estimate,
                    titleKey: "onboarding.page2.title",
                    bodyKey: "onboarding.page2.body"
                )
            case .send:
                OnboardingCarouselPage(
                    illustration: .send,
                    titleKey: "onboarding.page3.title",
                    bodyKey: "onboarding.page3.body"
                )
            case .business:
                OnboardingBusinessView(viewModel: viewModel)
            case .loadTariff:
                OnboardingLoadTariffView(onChoose: choose)
            }
        }
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .id(viewModel.step)
        .transition(.opacity)
    }

    // MARK: - Pie

    @ViewBuilder
    private var footer: some View {
        VStack(spacing: 12) {
            OnboardingPageIndicator(
                stepCount: viewModel.progressCount,
                currentIndex: viewModel.progressIndex
            )

            if let titleKey = viewModel.primaryTitleKey {
                Button {
                    primaryAction()
                } label: {
                    Text(LocalizedStringKey(titleKey))
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.isPrimaryEnabled)
            }
        }
        .frame(maxWidth: 560)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Acciones

    private func primaryAction() {
        if viewModel.mode == .walkthrough, viewModel.isLastVisibleStep {
            dismiss()
            return
        }
        animate { viewModel.primaryAction() }
    }

    private func choose(_ option: OnboardingViewModel.StartOption) {
        viewModel.start(with: option)
        switch option {
        case .importTariff, .pasteList:
            router.presentImport()
        case .addManually:
            router.presentNewItem()
        case .later:
            router.selectedTab = .prices
        }
    }

    private func animate(_ change: () -> Void) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
            change()
        }
    }
}

/// Indicador de página del carrusel (tres puntos).
private struct OnboardingPageIndicator: View {
    let stepCount: Int
    let currentIndex: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("onboarding.progress.label")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(progressDescription)
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(BrandPalette.accent)
            }
            HStack(spacing: 5) {
                ForEach(0..<stepCount, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentIndex ? BrandPalette.accent : BrandPalette.border)
                        .frame(maxWidth: .infinity)
                        .frame(height: 5)
                }
            }
        }
        .frame(minHeight: 30)
        .accessibilityElement()
        .accessibilityLabel(Text("onboarding.progress.label"))
        .accessibilityValue(Text(verbatim: progressDescription))
        .animation(.easeInOut(duration: 0.2), value: currentIndex)
    }

    private var progressDescription: String {
        String.localizedStringWithFormat(
            String(localized: "onboarding.progress.format"),
            currentIndex + 1,
            stepCount
        )
    }
}
