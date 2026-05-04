import SwiftUI

struct ToolConfigView: View {
    let stepType: StepType
    @Bindable var viewModel: AppViewModel
    let onDismiss: () -> Void

    @State private var searchText: String = ""
    @State private var replaceText: String = ""
    @State private var prefixText: String = ""
    @State private var suffixText: String = ""
    @State private var symbolText: String = ""
    @State private var columnIndex: Int = 0
    @State private var delimiter: String = ","
    @State private var ascending: Bool = true
    @State private var filterStrings: [String] = [""]
    @State private var selectedTemplateID: UUID?
    @State private var applied: Bool = false
    @State private var showBulkImport: Bool = false
    @State private var bulkImportText: String = ""
    @State private var useWildcard: Bool = false
    @State private var exceptions: [String] = [""]
    @State private var showExceptionsBulkImport: Bool = false
    @State private var clearOnly: Bool = false
    @State private var replaceWeakPasswords: Bool = false

    var body: some View {
        Form {
            Section {
                Label(stepType.displayName, systemImage: stepType.icon)
                    .font(.headline)
            }

            switch stepType {
            case .deduplicate, .trimLines, .removeEmptyLines, .extractEmails, .convertLogToDualFindData, .removeAllSpaces, .removeNonAlphanumericPrefix:
                Section {
                    Text(descriptionForType)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

            case .addPrefix:
                Section("Prefix") {
                    TextField("Enter prefix text", text: $prefixText)
                        .font(.system(.body, design: .monospaced))
                }

            case .addSuffix:
                Section("Suffix") {
                    TextField("Enter suffix text", text: $suffixText)
                        .font(.system(.body, design: .monospaced))
                }

            case .removePrefix:
                Section("Prefix to Remove") {
                    TextField("Enter prefix to remove", text: $prefixText)
                        .font(.system(.body, design: .monospaced))
                    Text("Case insensitive matching")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

            case .removeSuffix:
                Section("Suffix to Remove") {
                    TextField("Enter suffix to remove", text: $suffixText)
                        .font(.system(.body, design: .monospaced))
                    Text("Case insensitive matching")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

            case .sortAlphabetical, .sortByLength, .sortByEmail:
                Section("Order") {
                    Picker("Direction", selection: $ascending) {
                        Text("Ascending").tag(true)
                        Text("Descending").tag(false)
                    }
                    .pickerStyle(.segmented)
                }

            case .sortByColumnLength:
                Section("Column Settings") {
                    TextField("Delimiter", text: $delimiter)
                        .font(.system(.body, design: .monospaced))
                    Picker("Column", selection: $columnIndex) {
                        ForEach(0..<20, id: \.self) { i in
                            Text("Column \(i + 1)").tag(i)
                        }
                    }
                    Picker("Direction", selection: $ascending) {
                        Text("Shortest First").tag(true)
                        Text("Longest First").tag(false)
                    }
                    .pickerStyle(.segmented)
                }

            case .sortByColumn:
                Section("Column Settings") {
                    TextField("Delimiter", text: $delimiter)
                        .font(.system(.body, design: .monospaced))
                    Picker("Column", selection: $columnIndex) {
                        ForEach(0..<4, id: \.self) { i in
                            Text("Column \(i + 1)").tag(i)
                        }
                    }
                    Picker("Direction", selection: $ascending) {
                        Text("Ascending").tag(true)
                        Text("Descending").tag(false)
                    }
                    .pickerStyle(.segmented)
                }

            case .replaceText:
                Section("Find") {
                    TextField("Search text", text: $searchText)
                        .font(.system(.body, design: .monospaced))
                }
                Section("Replace With") {
                    TextField("Replacement text", text: $replaceText)
                        .font(.system(.body, design: .monospaced))
                }
                wildcardSection

            case .removeText:
                Section("Text to Remove") {
                    TextField("Enter text to remove all instances", text: $searchText)
                        .font(.system(.body, design: .monospaced))
                }
                wildcardSection

            case .removeBeforeSymbol:
                Section("Symbol") {
                    TextField("Enter symbol (e.g. @ : |)", text: $symbolText)
                        .font(.system(.body, design: .monospaced))
                    Text("Removes all text before this symbol in each line (case insensitive)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

            case .removeAfterSymbol:
                Section("Symbol") {
                    TextField("Enter symbol (e.g. @ : |)", text: $symbolText)
                        .font(.system(.body, design: .monospaced))
                    Text("Removes all text after this symbol in each line (case insensitive)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

            case .removeDuplicatesContaining:
                Section("String") {
                    TextField("Lines containing this string", text: $searchText)
                        .font(.system(.body, design: .monospaced))
                    Text("Among lines containing this string, duplicates will be removed (case insensitive)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                wildcardSection

            case .removeLinesContaining:
                filterStringsSection
                exceptionsSection
                wildcardSection
                clearOnlySection

            case .removeLinesNotContaining:
                filterStringsSection
                exceptionsSection
                wildcardSection

            case .removeLinesNoSymbolBetweenDelimiters:
                Section("Symbol to Find") {
                    TextField("Enter symbol (e.g. @)", text: $symbolText)
                        .font(.system(.body, design: .monospaced))
                }
                Section("Delimiter") {
                    TextField("Enter delimiter (e.g. ;)", text: $delimiter)
                        .font(.system(.body, design: .monospaced))
                    Text("Removes lines where the symbol does not appear between two delimiters.\nExample: keeps \"data;user@mail.com;info\" when symbol is \"@\" and delimiter is \";\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

            case .removeLinesNoSymbolInColumn:
                Section("Symbol to Find") {
                    TextField("Enter symbol (e.g. @)", text: $symbolText)
                        .font(.system(.body, design: .monospaced))
                }
                Section("Column Settings") {
                    TextField("Delimiter", text: $delimiter)
                        .font(.system(.body, design: .monospaced))
                    Picker("Column", selection: $columnIndex) {
                        ForEach(0..<20, id: \.self) { i in
                            Text("Column \(i + 1)").tag(i)
                        }
                    }
                    Text("Removes lines where the specified column does not contain the symbol (case insensitive).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

            case .fixPasswordsInColumn:
                Section("Column Settings") {
                    TextField("Delimiter", text: $delimiter)
                        .font(.system(.body, design: .monospaced))
                    Picker("Column", selection: $columnIndex) {
                        ForEach(0..<20, id: \.self) { i in
                            Text("Column \(i + 1)").tag(i)
                        }
                    }
                }
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Capitalise First Letter", systemImage: "textformat.abc")
                            .font(.subheadline.bold())
                        Text("If a cell has no uppercase letters, the first letter (left to right) will be capitalised.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Auto-Fix")
                }
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Minimum Password Requirements", systemImage: "xmark.shield")
                            .font(.subheadline.bold())
                        Text("Cells that fail these requirements will be handled:\n• 8 or more characters\n• At least 1 letter\n• At least 1 number")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)

                    Toggle(isOn: $replaceWeakPasswords) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Replace with Default Password")
                            Text("Use \"AAAa9998\" instead of clearing weak passwords")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Minimum Password Requirements")
                }

            case .convertSymbolToNewLines:
                Section("Symbol") {
                    TextField("Leave empty for space", text: $symbolText)
                        .font(.system(.body, design: .monospaced))
                    Text("Every occurrence of this symbol (or string) becomes a line break. Leave empty to split on spaces.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

            case .removeDuplicateCellsInColumn:
                Section("Column Settings") {
                    TextField("Delimiter", text: $delimiter)
                        .font(.system(.body, design: .monospaced))
                    Picker("Column", selection: $columnIndex) {
                        ForEach(0..<20, id: \.self) { i in
                            Text("Column \(i + 1)").tag(i)
                        }
                    }
                }
                Section {
                    Text("Removes lines where the chosen column's cell value has already appeared in a previous line. First occurrence is kept. Empty cells are preserved.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button {
                    applyTool()
                } label: {
                    HStack {
                        Spacer()
                        Label(applied ? "Applied" : "Apply", systemImage: applied ? "checkmark.circle.fill" : "play.fill")
                            .font(.headline)
                        Spacer()
                    }
                }
                .disabled(!isValid)
                .sensoryFeedback(.success, trigger: applied)
            }
        }
        .navigationTitle(stepType.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                }
            }
        }
        .onChange(of: searchText) { _, _ in applied = false }
        .onChange(of: replaceText) { _, _ in applied = false }
        .onChange(of: prefixText) { _, _ in applied = false }
        .onChange(of: suffixText) { _, _ in applied = false }
        .onChange(of: symbolText) { _, _ in applied = false }
        .onChange(of: ascending) { _, _ in applied = false }
        .onChange(of: useWildcard) { _, _ in applied = false }
    }

    private var clearOnlySection: some View {
        Section {
            Toggle(isOn: $clearOnly) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Blank Matching Lines")
                    Text("Clear the content instead of deleting the row")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var wildcardSection: some View {
        Section {
            Toggle(isOn: $useWildcard) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Wildcard Mode")
                    Text("Use * to match any single character")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Options")
        } footer: {
            if useWildcard {
                Text("Example: \"h*llo\" matches \"hello\", \"hallo\", \"hxllo\", etc.")
            }
        }
    }

    private var filterStringsSection: some View {
        Group {
            Section {
                if filterStrings.count <= 50 {
                    ForEach(Array(filterStrings.enumerated()), id: \.offset) { index, _ in
                        HStack {
                            TextField("String \(index + 1)", text: Binding(
                                get: { filterStrings.indices.contains(index) ? filterStrings[index] : "" },
                                set: { if filterStrings.indices.contains(index) { filterStrings[index] = $0 } }
                            ))
                            .font(.system(.body, design: .monospaced))

                            if filterStrings.count > 1 {
                                Button(role: .destructive) {
                                    filterStrings.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if filterStrings.count < 50000 {
                        Button {
                            filterStrings.append("")
                        } label: {
                            Label("Add String", systemImage: "plus.circle")
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("\(filterStrings.filter { !$0.isEmpty }.count.formatted()) strings loaded", systemImage: "text.line.last.and.arrowtriangle.forward")
                            .font(.subheadline.bold())
                        if let first = filterStrings.first(where: { !$0.isEmpty }) {
                            Text("First: \(first)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        if let last = filterStrings.last(where: { !$0.isEmpty }) {
                            Text("Last: \(last)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 4)

                    Button(role: .destructive) {
                        filterStrings = [""]
                    } label: {
                        Label("Clear All Strings", systemImage: "trash")
                    }
                }
            } header: {
                let activeCount = filterStrings.filter { !$0.isEmpty }.count
                Text("Strings to Match (\(activeCount.formatted()) active)")
            }

            Section {
                Button {
                    showBulkImport = true
                } label: {
                    Label("Bulk Import", systemImage: "doc.on.clipboard")
                }

                if !viewModel.templates.isEmpty {
                    Menu("Load from Template") {
                        ForEach(viewModel.templates) { template in
                            Button(template.name) {
                                filterStrings = template.strings
                            }
                        }
                    }
                }
            } header: {
                Text("Quick Add")
            } footer: {
                if stepType == .removeLinesContaining {
                    Text("Lines containing any of these strings will be removed (case insensitive).")
                } else {
                    Text("Only lines containing at least one of these strings will be kept (case insensitive).")
                }
            }
        }
        .sheet(isPresented: $showBulkImport) {
            BulkImportSheet(existingCount: filterStrings.filter({ !$0.isEmpty }).count) { imported in
                let nonEmpty = imported.filter { !$0.isEmpty }
                let existingActive = filterStrings.filter { !$0.isEmpty }
                let combined = existingActive + nonEmpty
                let capped = Array(combined.prefix(50000))
                filterStrings = capped.isEmpty ? [""] : capped
                applied = false
            }
        }
    }

    private var exceptionsSection: some View {
        Group {
            Section {
                ForEach(Array(exceptions.enumerated()), id: \.offset) { index, _ in
                    HStack {
                        TextField("Exception \(index + 1)", text: Binding(
                            get: { exceptions.indices.contains(index) ? exceptions[index] : "" },
                            set: { if exceptions.indices.contains(index) { exceptions[index] = $0 } }
                        ))
                        .font(.system(.body, design: .monospaced))

                        if exceptions.count > 1 {
                            Button(role: .destructive) {
                                exceptions.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if exceptions.count < 200 {
                    Button {
                        exceptions.append("")
                    } label: {
                        Label("Add Exception (\(exceptions.count)/200)", systemImage: "plus.circle")
                    }
                }
            } header: {
                Text("Exceptions (\(exceptions.filter { !$0.isEmpty }.count) active)")
            } footer: {
                if stepType == .removeLinesContaining {
                    Text("Lines matching an exception will be kept even if they match a filter string.\nExample: Remove rows containing \"/*-*/\" except \"/en-au/\"")
                } else {
                    Text("Lines matching an exception will be kept even if they don't match any filter string.")
                }
            }

            Section {
                Button {
                    showExceptionsBulkImport = true
                } label: {
                    Label("Bulk Import Exceptions", systemImage: "doc.on.clipboard")
                }
            }
        }
        .sheet(isPresented: $showExceptionsBulkImport) {
            BulkImportSheet(existingCount: exceptions.filter({ !$0.isEmpty }).count) { imported in
                let nonEmpty = imported.filter { !$0.isEmpty }
                let existingActive = exceptions.filter { !$0.isEmpty }
                let combined = existingActive + nonEmpty
                let capped = Array(combined.prefix(200))
                exceptions = capped.isEmpty ? [""] : capped
                applied = false
            }
        }
    }

    private var descriptionForType: String {
        switch stepType {
        case .deduplicate: "Removes duplicate lines while preserving the original order (case insensitive comparison)."
        case .trimLines: "Removes leading and trailing whitespace from each line."
        case .removeEmptyLines: "Removes all blank or whitespace-only lines."
        case .extractEmails: "Extracts all email addresses found in the text, one per line."
        case .convertLogToDualFindData: "Parses a URL/USER/PASS credential log and generates a frequency report showing usernames and passwords sorted by how often they appear."
        case .removeAllSpaces: "Removes every space character from the text."
        case .removeNonAlphanumericPrefix: "Trims any leading characters that aren't letters or numbers from each line (e.g. bullets, dashes, spaces)."
        default: ""
        }
    }

    private var isValid: Bool {
        switch stepType {
        case .deduplicate, .trimLines, .removeEmptyLines, .extractEmails,
             .sortAlphabetical, .sortByLength, .sortByEmail,
             .convertLogToDualFindData,
             .removeAllSpaces, .convertSymbolToNewLines, .removeNonAlphanumericPrefix:
            true
        case .sortByColumnLength:
            !delimiter.isEmpty
        case .addPrefix, .removePrefix:
            !prefixText.isEmpty
        case .addSuffix, .removeSuffix:
            !suffixText.isEmpty
        case .sortByColumn:
            !delimiter.isEmpty
        case .replaceText:
            !searchText.isEmpty
        case .removeText, .removeDuplicatesContaining:
            !searchText.isEmpty
        case .removeBeforeSymbol, .removeAfterSymbol:
            !symbolText.isEmpty
        case .removeLinesContaining, .removeLinesNotContaining:
            filterStrings.contains { !$0.isEmpty }
        case .removeLinesNoSymbolBetweenDelimiters:
            !symbolText.isEmpty && !delimiter.isEmpty
        case .removeLinesNoSymbolInColumn:
            !symbolText.isEmpty && !delimiter.isEmpty
        case .fixPasswordsInColumn:
            !delimiter.isEmpty
        case .removeDuplicateCellsInColumn:
            !delimiter.isEmpty
        }
    }

    private func applyTool() {
        let step = ProcessingStep(
            type: stepType,
            searchText: searchText,
            replaceText: replaceText,
            prefix: prefixText,
            suffix: suffixText,
            symbol: symbolText,
            columnIndex: columnIndex,
            delimiter: delimiter,
            ascending: ascending,
            strings: filterStrings,
            useWildcard: useWildcard,
            exceptions: exceptions,
            clearOnly: clearOnly,
            replaceWeakPasswords: replaceWeakPasswords
        )
        if (stepType == .removeLinesContaining || stepType == .removeLinesNotContaining) && filterStrings.filter({ !$0.isEmpty }).count > 10 {
            Task {
                await viewModel.applyStepAsync(step)
                applied = true
            }
        } else {
            viewModel.applyStep(step)
            applied = true
        }
    }
}
