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
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .frame(minHeight: 44)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .id(viewModel.step)
        .transition(.opacity)
    }

    // MARK: - Pie

    @ViewBuilder
    private var footer: some View {
        VStack(spacing: 12) {
            if viewModel.showsPageIndicator {
                OnboardingPageIndicator(
                    pageCount: viewModel.pageCount,
                    currentIndex: viewModel.pageIndex
                )
            }

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
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
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
    let pageCount: Int
    let currentIndex: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule()
                    .fill(index == currentIndex ? BrandPalette.accent : BrandPalette.border)
                    .frame(width: index == currentIndex ? 22 : 8, height: 8)
            }
        }
        .frame(minHeight: 20)
        .accessibilityElement()
        .accessibilityLabel(Text("onboarding.page.indicator"))
        .accessibilityValue(Text(verbatim: "\(currentIndex + 1)/\(pageCount)"))
    }
}
