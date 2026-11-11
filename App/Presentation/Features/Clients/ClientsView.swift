import SwiftUI
import QuoteCore

/// Pestaña Clientes: directorio derivado de los presupuestos guardados.
/// No hay una entidad `Client` propia en la v1 (D-021).
struct ClientsView: View {
    @Bindable var viewModel: ClientsViewModel
    @Environment(AppRouter.self) private var router

    var body: some View {
        List {
            Section {
                ForEach(viewModel.filteredGroups) { group in
                    NavigationLink {
                        ClientDetailView(clientID: group.id, viewModel: viewModel)
                    } label: {
                        ClientRow(group: group)
                    }
                }
            } footer: {
                Text("clients.groups.footer")
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $viewModel.searchText, prompt: "clients.search")
        .navigationTitle("clients.title")
        .navigationBarTitleDisplayMode(.large)
        .overlay { emptyOverlay }
        .task { viewModel.load() }
        .onChange(of: router.selectedTab) { _, tab in
            if tab == .clients { viewModel.load() }
        }
        .alert(
            "error.title",
            isPresented: Binding(
                get: {
                    if case .failed = viewModel.state { return true } else { return false }
                },
                set: { presented in
                    if !presented { viewModel.load() }
                }
            )
        ) {
            Button("action.ok", role: .cancel) {}
        } message: {
            if case .failed(let message) = viewModel.state {
                Text(LocalizedStringKey(message))
            }
        }
    }

    @ViewBuilder
    private var emptyOverlay: some View {
        if viewModel.state == .loaded && viewModel.filteredGroups.isEmpty {
            ContentUnavailableView {
                Label("clients.empty", systemImage: "person.2")
            } description: {
                Text(
                    viewModel.searchText.isEmpty
                        ? "clients.empty.message"
                        : "clients.empty.search"
                )
            }
        }
    }
}

private struct ClientRow: View {
    let group: ClientGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(group.client.name)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1)

            HStack(spacing: 8) {
                if !group.client.phone.isEmpty {
                    Text(group.client.phone)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(verbatim: quoteCountText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(group.lastDate, format: .dateTime.day().month().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var quoteCountText: String {
        let key = group.quoteCount == 1
            ? "clients.quoteCount.one"
            : "clients.quoteCount.other"
        return String.localizedStringWithFormat(
            NSLocalizedString(key, comment: ""),
            group.quoteCount
        )
    }
}

private struct ClientDetailView: View {
    let clientID: String
    @Bindable var viewModel: ClientsViewModel
    @Environment(AppRouter.self) private var router

    private var group: ClientGroup? {
        viewModel.groups.first { $0.id == clientID }
    }

    var body: some View {
        Group {
            if let group {
                content(for: group)
            } else {
                ContentUnavailableView {
                    Label("clients.empty", systemImage: "person.2")
                } description: {
                    Text("clients.empty.message")
                }
            }
        }
        .navigationTitle(group?.client.name ?? String(localized: "clients.title"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "error.title",
            isPresented: Binding(
                get: { viewModel.actionError != nil },
                set: { presented in
                    if !presented { viewModel.clearActionError() }
                }
            )
        ) {
            Button("action.ok", role: .cancel) {
                viewModel.clearActionError()
            }
        } message: {
            if let message = viewModel.actionError {
                Text(LocalizedStringKey(message))
            }
        }
    }

    private func content(for group: ClientGroup) -> some View {
        List {
            if hasContact(group.client) {
                Section {
                    if !group.client.phone.isEmpty {
                        LabeledContent("clients.phone", value: group.client.phone)
                    }
                    if !group.client.address.isEmpty {
                        LabeledContent("clients.address", value: group.client.address)
                    }
                    if let workAddress = group.client.workAddress, !workAddress.isEmpty {
                        LabeledContent("clients.workAddress", value: workAddress)
                    }
                } header: {
                    Text("clients.contact")
                }
            }

            Section {
                ForEach(group.quotes) { quote in
                    Button {
                        router.openQuote(quote.id)
                    } label: {
                        QuoteRow(
                            quote: quote,
                            total: viewModel.totals(for: quote).total,
                            showsClientName: false
                        )
                    }
                }
            } header: {
                Text("clients.quotes")
            }
        }
        .listStyle(.insetGrouped)
        .safeAreaInset(edge: .bottom) {
            Button {
                if let created = viewModel.createQuote(for: group) {
                    router.openQuote(created.id)
                }
            } label: {
                Label("clients.newQuote", systemImage: "plus")
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.bar)
            .accessibilityLabel("clients.newQuote")
        }
    }

    private func hasContact(_ client: Client) -> Bool {
        !client.phone.isEmpty
            || !client.address.isEmpty
            || !(client.workAddress ?? "").isEmpty
    }
}
