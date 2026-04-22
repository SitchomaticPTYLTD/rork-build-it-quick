import Foundation

nonisolated enum StepType: String, Codable, Sendable, CaseIterable {
    case deduplicate
    case addPrefix
    case addSuffix
    case removePrefix
    case removeSuffix
    case sortAlphabetical
    case sortByLength
    case sortByColumn
    case sortByColumnLength
    case replaceText
    case removeText
    case extractEmails
    case sortByEmail
    case removeBeforeSymbol
    case removeAfterSymbol
    case removeDuplicatesContaining
    case removeLinesContaining
    case removeLinesNotContaining
    case removeLinesNoSymbolBetweenDelimiters
    case removeLinesNoSymbolInColumn
    case trimLines
    case removeEmptyLines
    case fixPasswordsInColumn
    case removeDuplicateCellsInColumn
    case convertLogToDualFindData

    var displayName: String {
        switch self {
        case .deduplicate: "Deduplicate Lines"
        case .addPrefix: "Add Prefix"
        case .addSuffix: "Add Suffix"
        case .removePrefix: "Remove Prefix"
        case .removeSuffix: "Remove Suffix"
        case .sortAlphabetical: "Sort Alphabetically"
        case .sortByLength: "Sort by Length"
        case .sortByColumn: "Sort by Column"
        case .sortByColumnLength: "Sort by Column Length"
        case .replaceText: "Find & Replace"
        case .removeText: "Remove All Instances"
        case .extractEmails: "Extract Emails"
        case .sortByEmail: "Sort by Email"
        case .removeBeforeSymbol: "Remove Before Symbol"
        case .removeAfterSymbol: "Remove After Symbol"
        case .removeDuplicatesContaining: "Dedup Lines Containing"
        case .removeLinesContaining: "Remove Lines Containing"
        case .removeLinesNotContaining: "Remove Lines Not Containing"
        case .removeLinesNoSymbolBetweenDelimiters: "Remove Lines Without Symbol Between Delimiters"
        case .removeLinesNoSymbolInColumn: "Remove Lines Without Symbol in Column"
        case .trimLines: "Trim Whitespace"
        case .removeEmptyLines: "Remove Empty Lines"
        case .fixPasswordsInColumn: "Fix Passwords in Column"
        case .removeDuplicateCellsInColumn: "Remove Duplicate Cells in Column"
        case .convertLogToDualFindData: "Convert Log to Frequency Report"
        }
    }

    var icon: String {
        switch self {
        case .deduplicate: "minus.circle"
        case .addPrefix: "text.badge.plus"
        case .addSuffix: "text.badge.plus"
        case .removePrefix: "text.badge.minus"
        case .removeSuffix: "text.badge.minus"
        case .sortAlphabetical: "textformat.abc"
        case .sortByLength: "ruler"
        case .sortByColumn: "tablecells"
        case .sortByColumnLength: "ruler"
        case .replaceText: "arrow.left.arrow.right"
        case .removeText: "xmark.circle"
        case .extractEmails: "envelope"
        case .sortByEmail: "at"
        case .removeBeforeSymbol: "scissors"
        case .removeAfterSymbol: "scissors"
        case .removeDuplicatesContaining: "doc.on.doc"
        case .removeLinesContaining: "line.3.horizontal.decrease"
        case .removeLinesNotContaining: "line.3.horizontal.decrease.circle"
        case .removeLinesNoSymbolBetweenDelimiters: "at.circle"
        case .removeLinesNoSymbolInColumn: "tablecells.badge.ellipsis"
        case .trimLines: "wand.and.rays"
        case .removeEmptyLines: "text.badge.minus"
        case .fixPasswordsInColumn: "key.fill"
        case .removeDuplicateCellsInColumn: "tablecells.badge.ellipsis"
        case .convertLogToDualFindData: "chart.bar.doc.horizontal"
        }
    }

    var category: StepCategory {
        switch self {
        case .deduplicate, .trimLines, .removeEmptyLines, .fixPasswordsInColumn, .removeDuplicateCellsInColumn, .convertLogToDualFindData: .clean
        case .sortAlphabetical, .sortByLength, .sortByColumn, .sortByColumnLength, .sortByEmail: .sort
        case .addPrefix, .addSuffix, .removePrefix, .removeSuffix: .prefixSuffix
        case .replaceText, .removeText, .removeBeforeSymbol, .removeAfterSymbol: .findReplace
        case .extractEmails: .extract
        case .removeDuplicatesContaining, .removeLinesContaining, .removeLinesNotContaining, .removeLinesNoSymbolBetweenDelimiters, .removeLinesNoSymbolInColumn: .filterLines
        }
    }
}

nonisolated enum StepCategory: String, Sendable, CaseIterable {
    case clean = "Clean"
    case sort = "Sort"
    case prefixSuffix = "Prefix & Suffix"
    case findReplace = "Find & Replace"
    case extract = "Extract"
    case filterLines = "Filter Lines"

    var icon: String {
        switch self {
        case .clean: "sparkles"
        case .sort: "arrow.up.arrow.down"
        case .prefixSuffix: "textformat"
        case .findReplace: "magnifyingglass"
        case .extract: "envelope"
        case .filterLines: "line.3.horizontal.decrease"
        }
    }

    var steps: [StepType] {
        StepType.allCases.filter { $0.category == self }
    }
}

nonisolated struct ProcessingStep: Identifiable, Sendable, Hashable, Codable {
    let id: UUID
    let type: StepType
    var searchText: String
    var replaceText: String
    var prefix: String
    var suffix: String
    var symbol: String
    var columnIndex: Int
    var delimiter: String
    var ascending: Bool
    var strings: [String]
    var useWildcard: Bool
    var exceptions: [String]
    var clearOnly: Bool
    var replaceWeakPasswords: Bool

    init(
        id: UUID = UUID(),
        type: StepType,
        searchText: String = "",
        replaceText: String = "",
        prefix: String = "",
        suffix: String = "",
        symbol: String = "",
        columnIndex: Int = 0,
        delimiter: String = ",",
        ascending: Bool = true,
        strings: [String] = [],
        useWildcard: Bool = false,
        exceptions: [String] = [],
        clearOnly: Bool = false,
        replaceWeakPasswords: Bool = false
    ) {
        self.id = id
        self.type = type
        self.searchText = searchText
        self.replaceText = replaceText
        self.prefix = prefix
        self.suffix = suffix
        self.symbol = symbol
        self.columnIndex = columnIndex
        self.delimiter = delimiter
        self.ascending = ascending
        self.strings = strings
        self.useWildcard = useWildcard
        self.exceptions = exceptions
        self.clearOnly = clearOnly
        self.replaceWeakPasswords = replaceWeakPasswords
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        type = try container.decode(StepType.self, forKey: .type)
        searchText = try container.decodeIfPresent(String.self, forKey: .searchText) ?? ""
        replaceText = try container.decodeIfPresent(String.self, forKey: .replaceText) ?? ""
        prefix = try container.decodeIfPresent(String.self, forKey: .prefix) ?? ""
        suffix = try container.decodeIfPresent(String.self, forKey: .suffix) ?? ""
        symbol = try container.decodeIfPresent(String.self, forKey: .symbol) ?? ""
        columnIndex = try container.decodeIfPresent(Int.self, forKey: .columnIndex) ?? 0
        delimiter = try container.decodeIfPresent(String.self, forKey: .delimiter) ?? ","
        ascending = try container.decodeIfPresent(Bool.self, forKey: .ascending) ?? true
        strings = try container.decodeIfPresent([String].self, forKey: .strings) ?? []
        useWildcard = try container.decodeIfPresent(Bool.self, forKey: .useWildcard) ?? false
        exceptions = try container.decodeIfPresent([String].self, forKey: .exceptions) ?? []
        clearOnly = try container.decodeIfPresent(Bool.self, forKey: .clearOnly) ?? false
        replaceWeakPasswords = try container.decodeIfPresent(Bool.self, forKey: .replaceWeakPasswords) ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case id, type, searchText, replaceText, prefix, suffix, symbol
        case columnIndex, delimiter, ascending, strings, useWildcard, exceptions, clearOnly, replaceWeakPasswords
    }

    var summary: String {
        switch type {
        case .deduplicate: "Remove duplicate lines"
        case .addPrefix: "Add prefix: \"\(prefix)\""
        case .addSuffix: "Add suffix: \"\(suffix)\""
        case .removePrefix: "Remove prefix: \"\(prefix)\""
        case .removeSuffix: "Remove suffix: \"\(suffix)\""
        case .sortAlphabetical: "Sort \(ascending ? "A-Z" : "Z-A")"
        case .sortByLength: "Sort by length \(ascending ? "short first" : "long first")"
        case .sortByColumn: "Sort column \(columnIndex + 1) by \(delimiter)"
        case .replaceText: "Replace \"\(searchText)\" with \"\(replaceText)\""
        case .removeText: "Remove all \"\(searchText)\""
        case .extractEmails: "Extract email addresses"
        case .sortByEmail: "Sort lines by email"
        case .removeBeforeSymbol: "Remove before \"\(symbol)\""
        case .removeAfterSymbol: "Remove after \"\(symbol)\""
        case .removeDuplicatesContaining: "Dedup lines with \"\(searchText)\""
        case .removeLinesContaining: "\(clearOnly ? "Clear" : "Remove") lines with \(strings.count) pattern(s)\(exceptions.isEmpty ? "" : " (\(exceptions.count) exception(s))")"
        case .removeLinesNotContaining: "Keep lines with \(strings.count) pattern(s)\(exceptions.isEmpty ? "" : " (\(exceptions.count) exception(s))")"
        case .removeLinesNoSymbolBetweenDelimiters: "Keep lines with \"\(symbol)\" between \"\(delimiter)\" pairs"
        case .removeLinesNoSymbolInColumn: "Keep lines with \"\(symbol)\" in column \(columnIndex + 1)"
        case .trimLines: "Trim whitespace"
        case .removeEmptyLines: "Remove empty lines"
        case .fixPasswordsInColumn: "Fix passwords in column \(columnIndex + 1)\(replaceWeakPasswords ? " (replace weak)" : "")"
        case .removeDuplicateCellsInColumn: "Remove lines with duplicate cells in column \(columnIndex + 1)"
        case .sortByColumnLength: "Sort by length of column \(columnIndex + 1) (\(ascending ? "short first" : "long first"))"
        case .convertLogToDualFindData: "Convert URL/USER/PASS log to frequency report"
        }
    }
}

nonisolated struct ScriptTemplate: Codable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var steps: [ProcessingStep]
    var createdAt: Date

    init(id: UUID = UUID(), name: String = "New Script", steps: [ProcessingStep] = [], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.steps = steps
        self.createdAt = createdAt
    }
}

nonisolated struct LineRemovalTemplate: Codable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var strings: [String]
    var createdAt: Date

    init(id: UUID = UUID(), name: String = "New Template", strings: [String] = [""], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.strings = strings
        self.createdAt = createdAt
    }
}
