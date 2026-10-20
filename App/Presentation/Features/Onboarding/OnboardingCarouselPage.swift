import SwiftUI

/// Una página del carrusel: ilustración, título, explicación y, si la
/// hay, una línea pequeña. Centrada y con scroll para Dynamic Type.
struct OnboardingCarouselPage: View {
    let illustration: OnboardingIllustration
    let titleKey: LocalizedStringKey
    let bodyKey: LocalizedStringKey
    var noteKey: LocalizedStringKey?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                OnboardingIllustrationView(illustration: illustration)
                    .frame(height: 150)
                    .accessibilityHidden(true)

                VStack(spacing: 12) {
                    Text(titleKey)
                        .font(.largeTitle.weight(.bold))
                        .multilineTextAlignment(.center)
                    Text(bodyKey)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityElement(children: .combine)

                if let noteKey {
                    Label(noteKey, systemImage: "lock.fill")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .containerRelativeFrame(.vertical, alignment: .center)
        }
        .scrollBounceBehavior(.basedOnSize)
        .opacity(isVisible || reduceMotion ? 1 : 0)
        .scaleEffect(isVisible || reduceMotion ? 1 : 0.96)
        .onAppear {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.35)) {
                isVisible = true
            }
        }
    }
}
