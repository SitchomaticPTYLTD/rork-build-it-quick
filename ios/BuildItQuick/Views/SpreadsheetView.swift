import SwiftUI
import UniformTypeIdentifiers

struct SpreadsheetView: View {
    @Bindable var viewModel: AppViewModel
    @State private var delimiter: String = ","
    @State private var rows: [[String]] = []
    @State private var columnCount: Int = 0
    @State private var sortColumn: Int? = nil
    @State private var isParsed: Bool = false
    @State private var showColumnExport: Bool = false
    @State private var exportColumnIndex: Int = 0
    @State private var showExporter: Bool = false
    @State private var columnCSVText: String = ""

    private let maxColumns = 4
    private let maxRows = 25000
    private let columnWidth: CGFloat = 160

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                delimiterBar

                if isParsed && !rows.isEmpty {
                    statsRow

                    ScrollView(.horizontal) {
                        VStack(spacing: 0) {
                            headerRow

                            Divider()

                            ScrollView(.vertical) {
                                LazyVStack(spacing: 0) {
                                    ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                                        dataRow(index: index, row: row)
                                    }
                                }
                            }
                        }
                        .frame(minWidth: CGFloat(columnCount) * columnWidth + 60)
                    }
                    .contentMargins(.horizontal, 0)

                    applyBar
                } else {
                    ContentUnavailableView(
                        "No Data",
                        systemImage: "tablecells",
                        description: Text("Enter a delimiter and tap Parse to view your text as a spreadsheet.\n\nMax \(maxColumns) columns, \(maxRows.formatted()) rows.")
                    )
                }
            }
            .navigationTitle("Spreadsheet")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showColumnExport) {
                columnExportSheet
            }
            .fileExporter(
                isPresented: $showExporter,
                document: TextFile(text: columnCSVText),
                contentType: .commaSeparatedText,
                defaultFilename: "column_\(exportColumnIndex + 1).csv"
            ) { _ in }
        }
    }

    private var delimiterBar: some View {
        HStack(spacing: 12) {
            Text("Delimiter")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("Symbol", text: $delimiter)
                .font(.system(.body, design: .monospaced))
                .frame(width: 60)
                .textFieldStyle(.roundedBorder)

            Button("Parse") {
                parseText()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(delimiter.isEmpty || viewModel.text.isEmpty)

            Spacer()

            if isParsed {
                Button("Clear") {
                    rows = []
                    columnCount = 0
                    isParsed = false
                }
                .controlSize(.small)
                .foregroundStyle(.red)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemGroupedBackground))
    }

    private var statsRow: some View {
        HStack {
            Text("\(rows.count) rows")
            Text("\(columnCount) columns")
            Spacer()
            if let col = sortColumn {
                Text("Sorted by Col \(col + 1)")
                    .foregroundStyle(.blue)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text("#")
                .font(.caption.bold())
                .frame(width: 50, alignment: .center)
                .padding(.vertical, 8)
                .background(Color(.tertiarySystemBackground))

            ForEach(0..<columnCount, id: \.self) { col in
                Menu {
                    Button {
                        sortRows(by: col, mode: .alphabeticalAsc)
                    } label: {
                        Label("Sort A-Z", systemImage: "textformat.abc")
                    }
                    Button {
                        sortRows(by: col, mode: .alphabeticalDesc)
                    } label: {
                        Label("Sort Z-A", systemImage: "textformat.abc")
                    }
                    Divider()
                    Button {
                        sortRows(by: col, mode: .lengthAsc)
                    } label: {
                        Label("Shortest First", systemImage: "ruler")
                    }
                    Button {
                        sortRows(by: col, mode: .lengthDesc)
                    } label: {
                        Label("Longest First", systemImage: "ruler")
                    }
                    Divider()
                    Button {
                        sortRows(by: col, mode: .numericAsc)
                    } label: {
                        Label("Numeric 0-9", systemImage: "number")
                    }
                    Button {
                        sortRows(by: col, mode: .numericDesc)
                    } label: {
                        Label("Numeric 9-0", systemImage: "number")
                    }
                    Divider()
                    Button {
                        exportColumnIndex = col
                        columnCSVText = viewModel.exportColumnCSV(rows: rows, columnIndex: col, delimiter: delimiter)
                        showColumnExport = true
                    } label: {
                        Label("Export Column as CSV", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Column \(col + 1)")
                            .font(.caption.bold())
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                    }
                    .frame(width: columnWidth, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(
                        sortColumn == col
                            ? Color.blue.opacity(0.15)
                            : Color(.tertiarySystemBackground)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func dataRow(index: Int, row: [String]) -> some View {
        HStack(spacing: 0) {
            Text("\(index + 1)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .center)

            ForEach(0..<columnCount, id: \.self) { col in
                Text(col < row.count ? row[col] : "")
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(1)
                    .frame(width: columnWidth, alignment: .leading)
                    .padding(.horizontal, 8)
            }
        }
        .padding(.vertical, 4)
        .background(index % 2 == 0 ? Color.clear : Color(.systemGray6).opacity(0.5))
    }

    private var applyBar: some View {
        Button {
            applyToText()
        } label: {
            HStack {
                Spacer()
                Label("Apply Changes to Text", systemImage: "arrow.down.doc")
                    .font(.subheadline.bold())
                Spacer()
            }
        }
        .buttonStyle(.borderedProminent)
        .padding()
    }

    private var columnExportSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Column \(exportColumnIndex + 1)")
                        .font(.headline)
                    Text("\(rows.count) values")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                ScrollView {
                    Text(columnCSVText)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .background(Color(.secondarySystemBackground))
                .clipShape(.rect(cornerRadius: 8))
                .padding(.horizontal)

                HStack(spacing: 12) {
                    Button {
                        UIPasteboard.general.string = columnCSVText
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        showColumnExport = false
                        showExporter = true
                    } label: {
                        Label("Save as CSV", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Export Column")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showColumnExport = false }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func parseText() {
        let lines = viewModel.text.components(separatedBy: "\n").filter { !$0.isEmpty }
        let capped = Array(lines.prefix(maxRows))
        let parsed = capped.map { line in
            let cols = line.components(separatedBy: delimiter)
            return Array(cols.prefix(maxColumns))
        }
        columnCount = min(maxColumns, parsed.map(\.count).max() ?? 0)
        rows = parsed.map { row in
            var padded = row
            while padded.count < columnCount {
                padded.append("")
            }
            return padded
        }
        sortColumn = nil
        isParsed = true
    }

    private enum SortMode {
        case alphabeticalAsc, alphabeticalDesc, lengthAsc, lengthDesc, numericAsc, numericDesc
    }

    private func sortRows(by column: Int, mode: SortMode) {
        rows.sort { a, b in
            let valA = column < a.count ? a[column].trimmingCharacters(in: .whitespaces) : ""
            let valB = column < b.count ? b[column].trimmingCharacters(in: .whitespaces) : ""
            switch mode {
            case .alphabeticalAsc:
                return valA.localizedCaseInsensitiveCompare(valB) == .orderedAscending
            case .alphabeticalDesc:
                return valA.localizedCaseInsensitiveCompare(valB) == .orderedDescending
            case .lengthAsc:
                return valA.count < valB.count
            case .lengthDesc:
                return valA.count > valB.count
            case .numericAsc:
                let numA = Double(valA) ?? Double.infinity
                let numB = Double(valB) ?? Double.infinity
                return numA < numB
            case .numericDesc:
                let numA = Double(valA) ?? -Double.infinity
                let numB = Double(valB) ?? -Double.infinity
                return numA > numB
            }
        }
        sortColumn = column
    }

    private func applyToText() {
        let newText = rows.map { $0.joined(separator: delimiter) }.joined(separator: "\n")
        viewModel.text = newText
    }
}
