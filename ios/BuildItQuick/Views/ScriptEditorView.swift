import SwiftUI

struct ScriptEditorView: View {
    @Bindable var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var script: ScriptTemplate
    @State private var showAddStep: Bool = false
    let onSave: (ScriptTemplate) -> Void

    init(viewModel: AppViewModel, script: ScriptTemplate, onSave: @escaping (ScriptTemplate) -> Void) {
        self.viewModel = viewModel
        self._script = State(initialValue: script)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Script Name") {
                    TextField("Name", text: $script.name)
                }

                Section {
                    if script.steps.isEmpty {
                        Text("No steps yet. Tap + to add processing steps.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(Array(script.steps.enumerated()), id: \.element.id) { index, step in
                            HStack(spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.caption.bold().monospacedDigit())
                                    .foregroundStyle(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Circle().fill(.blue))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(step.type.displayName)
                                        .font(.subheadline.bold())
                                    Text(step.summary)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .onDelete { offsets in
                            script.steps.remove(atOffsets: offsets)
                        }
                        .onMove { from, to in
                            script.steps.move(fromOffsets: from, toOffset: to)
                        }
                    }
                } header: {
                    HStack {
                        Text("Steps")
                        Spacer()
                        Button {
                            showAddStep = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }

                if !script.steps.isEmpty {
                    Section {
                        Button {
                            viewModel.runScript(script)
                        } label: {
                            HStack {
                                Spacer()
                                Label("Run on Current Text", systemImage: "play.fill")
                                    .font(.headline)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(script.name.isEmpty ? "New Script" : script.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(script)
                        dismiss()
                    }
                    .disabled(script.name.isEmpty)
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
            .sheet(isPresented: $showAddStep) {
                AddStepSheet { step in
                    script.steps.append(step)
                }
            }
        }
    }
}

struct AddStepSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: StepType? = nil
    @State private var searchText: String = ""
    @State private var replaceText: String = ""
    @State private var prefixText: String = ""
    @State private var suffixText: String = ""
    @State private var symbolText: String = ""
    @State private var columnIndex: Int = 0
    @State private var delimiter: String = ","
    @State private var ascending: Bool = true
    @State private var filterStrings: [String] = [""]
    @State private var showBulkImport: Bool = false
    @State private var useWildcard: Bool = false
    @State private var exceptions: [String] = [""]
    @State private var showExceptionsBulkImport: Bool = false
    @State private var replaceWeakPasswords: Bool = false
    let onAdd: (ProcessingStep) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if let stepType = selectedType {
                    stepConfigForm(stepType)
                } else {
                    stepTypeList
                }
            }
            .navigationTitle(selectedType?.displayName ?? "Add Step")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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
            .sheet(isPresented: $showBulkImport) {
                BulkImportSheet(existingCount: filterStrings.filter({ !$0.isEmpty }).count) { imported in
                    let nonEmpty = imported.filter { !$0.isEmpty }
                    let existingActive = filterStrings.filter { !$0.isEmpty }
                    let combined = existingActive + nonEmpty
                    let capped = Array(combined.prefix(200))
                    filterStrings = capped.isEmpty ? [""] : capped
                }
            }
            .sheet(isPresented: $showExceptionsBulkImport) {
                BulkImportSheet(existingCount: exceptions.filter({ !$0.isEmpty }).count) { imported in
                    let nonEmpty = imported.filter { !$0.isEmpty }
                    let existingActive = exceptions.filter { !$0.isEmpty }
                    let combined = existingActive + nonEmpty
                    let capped = Array(combined.prefix(200))
                    exceptions = capped.isEmpty ? [""] : capped
                }
            }
        }
    }

    private var stepTypeList: some View {
        List {
            ForEach(StepCategory.allCases, id: \.self) { category in
                Section(category.rawValue) {
                    ForEach(category.steps, id: \.self) { stepType in
                        Button {
                            selectedType = stepType
                        } label: {
                            Label(stepType.displayName, systemImage: stepType.icon)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }
    }

    private var supportsWildcard: Bool {
        guard let t = selectedType else { return false }
        switch t {
        case .replaceText, .removeText, .removeDuplicatesContaining,
             .removeLinesContaining, .removeLinesNotContaining:
            return true
        default:
            return false
        }
    }

    private var supportsExceptions: Bool {
        guard let t = selectedType else { return false }
        return t == .removeLinesContaining || t == .removeLinesNotContaining
    }

    private func stepConfigForm(_ stepType: StepType) -> some View {
        Form {
            switch stepType {
            case .deduplicate, .trimLines, .removeEmptyLines, .extractEmails, .convertLogToDualFindData:
                Section {
                    Text("This step requires no configuration.")
                        .foregroundStyle(.secondary)
                }

            case .addPrefix:
                Section("Prefix") {
                    TextField("Prefix text", text: $prefixText)
                        .font(.system(.body, design: .monospaced))
                }

            case .addSuffix:
                Section("Suffix") {
                    TextField("Suffix text", text: $suffixText)
                        .font(.system(.body, design: .monospaced))
                }

            case .removePrefix:
                Section("Prefix to Remove") {
                    TextField("Prefix", text: $prefixText)
                        .font(.system(.body, design: .monospaced))
                }

            case .removeSuffix:
                Section("Suffix to Remove") {
                    TextField("Suffix", text: $suffixText)
                        .font(.system(.body, design: .monospaced))
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
                    TextField("Replacement", text: $replaceText)
                        .font(.system(.body, design: .monospaced))
                }

            case .removeText:
                Section("Text to Remove") {
                    TextField("Text to remove", text: $searchText)
                        .font(.system(.body, design: .monospaced))
                }

            case .removeBeforeSymbol, .removeAfterSymbol:
                Section("Symbol") {
                    TextField("Symbol (e.g. @ : |)", text: $symbolText)
                        .font(.system(.body, design: .monospaced))
                }

            case .removeDuplicatesContaining:
                Section("String") {
                    TextField("Containing string", text: $searchText)
                        .font(.system(.body, design: .monospaced))
                }

            case .removeLinesNoSymbolBetweenDelimiters:
                Section("Symbol to Find") {
                    TextField("Enter symbol (e.g. @)", text: $symbolText)
                        .font(.system(.body, design: .monospaced))
                }
                Section("Delimiter") {
                    TextField("Enter delimiter (e.g. ;)", text: $delimiter)
                        .font(.system(.body, design: .monospaced))
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
                    Toggle(isOn: $replaceWeakPasswords) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Replace with Default Password")
                            Text("Use \"AAAa9998\" instead of clearing weak passwords")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Weak Password Handling")
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

            case .removeLinesContaining, .removeLinesNotContaining:
                Section("Strings") {
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
                    if filterStrings.count < 200 {
                        Button {
                            filterStrings.append("")
                        } label: {
                            Label("Add String (\(filterStrings.count)/200)", systemImage: "plus.circle")
                        }
                    }
                }
                Section {
                    Button {
                        showBulkImport = true
                    } label: {
                        Label("Bulk Import", systemImage: "doc.on.clipboard")
                    }
                }

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
                    Text("Exceptions")
                } footer: {
                    Text("Lines matching an exception are preserved regardless of filter matches.")
                }
                Section {
                    Button {
                        showExceptionsBulkImport = true
                    } label: {
                        Label("Bulk Import Exceptions", systemImage: "doc.on.clipboard")
                    }
                }
            }

            if supportsWildcard {
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
                }
            }

            Section {
                Button {
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
                        replaceWeakPasswords: replaceWeakPasswords
                    )
                    onAdd(step)
                    dismiss()
                } label: {
                    HStack {
                        Spacer()
                        Label("Add Step", systemImage: "plus.circle.fill")
                            .font(.headline)
                        Spacer()
                    }
                }
            }
        }
    }
}
