import PDFKit
import SwiftUI

struct QuotePreviewScreen: View {
    @State private var viewModel: QuotePreviewViewModel

    init(viewModel: QuotePreviewViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        QuotePreviewView(viewModel: viewModel)
    }
}

/// S6 Vista previa del PDF y hoja de compartir del sistema.
struct QuotePreviewView: View {
    @Bindable var viewModel: QuotePreviewViewModel

    var body: some View {
        Group {
            if let url = viewModel.pdfURL {
                PDFPreview(url: url)
                    .ignoresSafeArea(edges: .bottom)
            } else if case .failed(let message) = viewModel.state {
                ContentUnavailableView {
                    Label("quote.preview.error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(LocalizedStringKey(message))
                }
            } else {
                ProgressView("quote.preview.loading")
            }
        }
        .navigationTitle("quote.preview.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let url = viewModel.pdfURL {
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: url) {
                        Label("quote.preview.share", systemImage: "square.and.arrow.up")
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        viewModel.markSent()
                    })
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let url = viewModel.pdfURL {
                ShareLink(item: url) {
                    Label("quote.preview.share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.bar)
                .simultaneousGesture(TapGesture().onEnded {
                    viewModel.markSent()
                })
            }
        }
        .task { viewModel.load() }
    }
}

private struct PDFPreview: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.document = PDFDocument(url: url)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.documentURL != url {
            uiView.document = PDFDocument(url: url)
        }
    }
}
