import QuoteCore
import SwiftUI

/// S8 ImportTariff: cargar la tarifa del usuario desde Excel/CSV o pegando una
/// lista; asignar columnas, marcar si los precios llevan IVA, revisar y
/// confirmar. Nada se guarda sin pasar por la revisión. Ver docs/PRODUCT.md (S8).
struct ImportTariffView: View {
    @Bindable var viewModel: ImportTariffViewModel
    @Environment(AppRouter.self) private var router

    @State private var isChoosingFile = false
    @State private var templateURL: URL?

    var body: some View {
        content
            .navigationTitle("importTariff.title")
            .task { templateURL = try? viewModel.templateURL() }
            .fileImporter(
                isPresented: $isChoosingFile,
                allowedContentTypes: ImportFileTypes.allowed,
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    viewModel.loadFile(at: url)
                }
            }
    }

    // MARK: - Estados

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView("importTariff.loading")
        case .failed(let message):
            ContentUnavailableView {
                Label("importTariff.error.title", systemImage: "exclamationmark.triangle")
            } description: {
                Text(LocalizedStringKey(message))
            } actions: {
                Button("importTariff.error.retry") { viewModel.backToOrigin() }
                    .frame(minHeight: 56)
            }
        case .idle, .ready:
            stepContent
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        if let summary = viewModel.summary {
            completionView(summary)
        } else {
            switch viewModel.step {
            case .origin: originForm
            case .mapping: mappingForm
            case .review: reviewForm
            }
        }
    }

    // MARK: - Origen

    private var originForm: some View {
        Form {
            Section {
                Button {
                    isChoosingFile = true
                } label: {
                    Label("importTariff.origin.file.button", systemImage: "folder")
                        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                }
                Text("importTariff.origin.file.hint")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("importTariff.origin.file.title")
            }

            if let templateURL {
                Section {
                    ShareLink(item: templateURL) {
                        Label("importTariff.template.button", systemImage: "arrow.down.doc")
                            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                    }
                    Text("importTariff.template.hint")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("importTariff.template.title")
                }
            }

            Section {
                TextEditor(text: $viewModel.pastedText)
                    .frame(minHeight: 120)
                    .textInputAutocapitalization(.never)
                vatControls
                Button {
                    viewModel.loadPastedText()
                } label: {
                    Label("importTariff.origin.paste.button", systemImage: "text.badge.plus")
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } header: {
                Text("importTariff.origin.paste.title")
            } footer: {
                Text("importTariff.origin.paste.hint")
            }
        }
    }

    // MARK: - Mapeo

    private var mappingForm: some View {
        Form {
            if viewModel.tables.count > 1 {
                Section("importTariff.sheet.title") {
                    Picker("importTariff.sheet.picker", selection: $viewModel.selectedTableIndex) {
                        ForEach(Array(viewModel.tables.enumerated()), id: \.offset) { index, table in
                            Text(verbatim: table.name ?? "\(index + 1)").tag(index)
                        }
                    }
                    .onChange(of: viewModel.selectedTableIndex) { _, index in
                        viewModel.selectTable(index)
                    }
                }
            }

            Section("importTariff.mapping.preview") {
                previewGrid
            }

            Section("importTariff.mapping.columns") {
                Picker("importTariff.mapping.name", selection: $viewModel.mapping.name) {
                    ForEach(viewModel.columnOptions, id: \.self) { index in
                        Text(verbatim: viewModel.columnTitle(index)).tag(index)
                    }
                }
                optionalColumnPicker("importTariff.mapping.price", selection: $viewModel.mapping.price)
                optionalColumnPicker("importTariff.mapping.unit", selection: $viewModel.mapping.unit)
                optionalColumnPicker("importTariff.mapping.category", selection: $viewModel.mapping.category)
            }

            Section("importTariff.vat.title") {
                vatControls
            }

            Section {
                Button {
                    viewModel.continueToReview()
                } label: {
                    Label("importTariff.mapping.continue", systemImage: "checklist")
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canContinue)
            }
        }
    }

    private var previewGrid: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(viewModel.previewRows.enumerated()), id: \.offset) { rowIndex, row in
                    HStack(spacing: 10) {
                        ForEach(viewModel.columnOptions, id: \.self) { column in
                            Text(verbatim: column < row.count ? row[column] : "")
                                .font(rowIndex == 0 ? .caption.bold() : .caption)
                                .foregroundStyle(rowIndex == 0 ? .primary : .secondary)
                                .frame(minWidth: 84, alignment: .leading)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .accessibilityLabel("importTariff.mapping.preview.accessibility")
    }

    private func optionalColumnPicker(
        _ titleKey: LocalizedStringKey,
        selection: Binding<Int?>
    ) -> some View {
        Picker(titleKey, selection: selection) {
            Text("importTariff.mapping.none").tag(Int?.none)
            ForEach(viewModel.columnOptions, id: \.self) { index in
                Text(verbatim: viewModel.columnTitle(index)).tag(Int?.some(index))
            }
        }
    }

    // MARK: - Revisión

    private var reviewForm: some View {
        Form {
            Section {
                Picker("importTariff.review.mode", selection: $viewModel.mode) {
                    Text("importTariff.review.mode.update").tag(ImportMode.updateExisting)
                    Text("importTariff.review.mode.addNew").tag(ImportMode.addOnlyNew)
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } header: {
                Text("importTariff.review.mode.title")
            } footer: {
                Text("importTariff.review.mode.hint")
            }

            if viewModel.warningCount > 0 {
                Section {
                    HStack {
                        Label("importTariff.review.warningCount", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                        Spacer()
                        Text(verbatim: "\(viewModel.warningCount)")
                            .foregroundStyle(.orange)
                            .monospacedDigit()
                    }
                }
            }

            Section {
                ForEach(viewModel.rows) { row in
                    ImportRowEditor(
                        row: row,
                        unitLabel: { DomainLabels.measureUnit($0) },
                        onName: { viewModel.updateName($0, for: row.id) },
                        onUnit: { viewModel.updateUnit($0, for: row.id) },
                        onPrice: { viewModel.updatePrice($0, for: row.id) }
                    )
                }
                .onDelete { offsets in
                    for index in offsets {
                        viewModel.removeRow(viewModel.rows[index].id)
                    }
                }
            } header: {
                Text("importTariff.review.rows")
            } footer: {
                if let errorMessage = viewModel.errorMessage {
                    Text(LocalizedStringKey(errorMessage)).foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    viewModel.confirm()
                } label: {
                    Label("importTariff.review.confirm", systemImage: "tray.and.arrow.down")
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.rows.isEmpty)

                Button("importTariff.review.back") { viewModel.backToMapping() }
            }
        }
    }

    // MARK: - Fin

    private func completionView(_ summary: ImportTariff.Summary) -> some View {
        ContentUnavailableView {
            Label("importTariff.done.title", systemImage: "checkmark.circle")
        } description: {
            VStack(spacing: 6) {
                LabeledContent("importTariff.done.created", value: "\(summary.created)")
                LabeledContent("importTariff.done.updated", value: "\(summary.updated)")
                LabeledContent("importTariff.done.skipped", value: "\(summary.skipped)")
            }
        } actions: {
            Button {
                router.popToRoot()
            } label: {
                Text("importTariff.done.close")
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - IVA

    @ViewBuilder
    private var vatControls: some View {
        Toggle("importTariff.vat.toggle", isOn: $viewModel.vatIncluded)
        if viewModel.vatIncluded {
            Picker("importTariff.vat.rate", selection: $viewModel.vatRate) {
                ForEach(viewModel.vatRateOptions, id: \.self) { rate in
                    Text(verbatim: "\(rate) %").tag(rate)
                }
            }
        }
    }
}

// MARK: - Editor de fila

private struct ImportRowEditor: View {
    let row: ImportedRow
    let unitLabel: (MeasureUnit) -> String
    let onName: (String) -> Void
    let onUnit: (MeasureUnit) -> Void
    let onPrice: (String) -> Void

    @State private var priceText: String

    init(
        row: ImportedRow,
        unitLabel: @escaping (MeasureUnit) -> String,
        onName: @escaping (String) -> Void,
        onUnit: @escaping (MeasureUnit) -> Void,
        onPrice: @escaping (String) -> Void
    ) {
        self.row = row
        self.unitLabel = unitLabel
        self.onName = onName
        self.onUnit = onUnit
        self.onPrice = onPrice
        _priceText = State(initialValue: CurrencyFormatter.plainString(from: row.netPrice))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("importTariff.review.name", text: nameBinding)
                .font(.body)

            HStack(spacing: 12) {
                Picker("importTariff.review.unit", selection: unitBinding) {
                    ForEach(MeasureUnit.allCases, id: \.self) { unit in
                        Text(LocalizedStringKey(unitLabel(unit))).tag(unit)
                    }
                }
                .labelsHidden()

                TextField("importTariff.review.price", text: $priceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .onChange(of: priceText) { _, newValue in
                        onPrice(newValue)
                    }
            }

            ForEach(Array(row.warnings.enumerated()), id: \.offset) { _, warning in
                Label(LocalizedStringKey(DomainLabels.importWarning(warning)), systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 2)
    }

    private var nameBinding: Binding<String> {
        Binding(get: { row.name }, set: { onName($0) })
    }

    private var unitBinding: Binding<MeasureUnit> {
        Binding(get: { row.unit }, set: { onUnit($0) })
    }
}

#Preview {
    NavigationStack {
        ImportTariffView(
            viewModel: ImportTariffViewModel(
                source: LocalTariffSource(),
                template: FileTariffTemplateProvider(),
                importTariff: ImportTariff(items: PreviewItemRepository())
            )
        )
    }
    .environment(AppRouter())
}
