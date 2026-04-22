import Foundation

nonisolated enum TextProcessingService: Sendable {

    static func apply(_ step: ProcessingStep, to text: String) -> String {
        switch step.type {
        case .deduplicate: deduplicate(text)
        case .addPrefix: addPrefix(text, prefix: step.prefix)
        case .addSuffix: addSuffix(text, suffix: step.suffix)
        case .removePrefix: removePrefix(text, prefix: step.prefix)
        case .removeSuffix: removeSuffix(text, suffix: step.suffix)
        case .sortAlphabetical: sortAlphabetical(text, ascending: step.ascending)
        case .sortByLength: sortByLength(text, ascending: step.ascending)
        case .sortByColumn: sortByColumn(text, column: step.columnIndex, delimiter: step.delimiter, ascending: step.ascending)
        case .sortByColumnLength: sortByColumnLength(text, column: step.columnIndex, delimiter: step.delimiter, ascending: step.ascending)
        case .replaceText: replaceText(text, search: step.searchText, replacement: step.replaceText, useWildcard: step.useWildcard)
        case .removeText: replaceText(text, search: step.searchText, replacement: "", useWildcard: step.useWildcard)
        case .extractEmails: extractEmails(text)
        case .sortByEmail: sortByEmail(text, ascending: step.ascending)
        case .removeBeforeSymbol: removeBeforeSymbol(text, symbol: step.symbol)
        case .removeAfterSymbol: removeAfterSymbol(text, symbol: step.symbol)
        case .removeDuplicatesContaining: removeDuplicatesContaining(text, search: step.searchText, useWildcard: step.useWildcard)
        case .removeLinesContaining: removeLinesContaining(text, strings: step.strings, useWildcard: step.useWildcard, exceptions: step.exceptions, clearOnly: step.clearOnly)
        case .removeLinesNotContaining: removeLinesNotContaining(text, strings: step.strings, useWildcard: step.useWildcard, exceptions: step.exceptions)
        case .removeLinesNoSymbolBetweenDelimiters: removeLinesNoSymbolBetweenDelimiters(text, symbol: step.symbol, delimiter: step.delimiter)
        case .removeLinesNoSymbolInColumn: removeLinesNoSymbolInColumn(text, symbol: step.symbol, column: step.columnIndex, delimiter: step.delimiter)
        case .trimLines: trimLines(text)
        case .removeEmptyLines: removeEmptyLines(text)
        case .fixPasswordsInColumn: fixPasswordsInColumn(text, column: step.columnIndex, delimiter: step.delimiter, replaceWeak: step.replaceWeakPasswords)
        case .removeDuplicateCellsInColumn: removeDuplicateCellsInColumn(text, column: step.columnIndex, delimiter: step.delimiter)
        case .convertLogToDualFindData: convertLogToDualFindData(text)
        }
    }

    static func deduplicate(_ text: String) -> String {
        var seen = Set<String>()
        var result: [String] = []
        for line in text.components(separatedBy: "\n") {
            let key = line.lowercased()
            if !seen.contains(key) {
                seen.insert(key)
                result.append(line)
            }
        }
        return result.joined(separator: "\n")
    }

    static func addPrefix(_ text: String, prefix: String) -> String {
        guard !prefix.isEmpty else { return text }
        return text.components(separatedBy: "\n")
            .map { prefix + $0 }
            .joined(separator: "\n")
    }

    static func addSuffix(_ text: String, suffix: String) -> String {
        guard !suffix.isEmpty else { return text }
        return text.components(separatedBy: "\n")
            .map { $0 + suffix }
            .joined(separator: "\n")
    }

    static func removePrefix(_ text: String, prefix: String) -> String {
        guard !prefix.isEmpty else { return text }
        let lowerPrefix = prefix.lowercased()
        return text.components(separatedBy: "\n")
            .map { line in
                if line.lowercased().hasPrefix(lowerPrefix) {
                    return String(line.dropFirst(prefix.count))
                }
                return line
            }
            .joined(separator: "\n")
    }

    static func removeSuffix(_ text: String, suffix: String) -> String {
        guard !suffix.isEmpty else { return text }
        let lowerSuffix = suffix.lowercased()
        return text.components(separatedBy: "\n")
            .map { line in
                if line.lowercased().hasSuffix(lowerSuffix) {
                    return String(line.dropLast(suffix.count))
                }
                return line
            }
            .joined(separator: "\n")
    }

    static func sortAlphabetical(_ text: String, ascending: Bool) -> String {
        let lines = text.components(separatedBy: "\n")
        let sorted = ascending
            ? lines.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
            : lines.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedDescending }
        return sorted.joined(separator: "\n")
    }

    static func sortByLength(_ text: String, ascending: Bool) -> String {
        let lines = text.components(separatedBy: "\n")
        let sorted = ascending
            ? lines.sorted { $0.count < $1.count }
            : lines.sorted { $0.count > $1.count }
        return sorted.joined(separator: "\n")
    }

    static func sortByColumn(_ text: String, column: Int, delimiter: String, ascending: Bool) -> String {
        guard !delimiter.isEmpty else { return text }
        let lines = text.components(separatedBy: "\n")
        let sorted = lines.sorted { a, b in
            let colsA = a.components(separatedBy: delimiter)
            let colsB = b.components(separatedBy: delimiter)
            let valA = column < colsA.count ? colsA[column].trimmingCharacters(in: .whitespaces) : ""
            let valB = column < colsB.count ? colsB[column].trimmingCharacters(in: .whitespaces) : ""
            return ascending
                ? valA.localizedCaseInsensitiveCompare(valB) == .orderedAscending
                : valA.localizedCaseInsensitiveCompare(valB) == .orderedDescending
        }
        return sorted.joined(separator: "\n")
    }

    static func sortByColumnLength(_ text: String, column: Int, delimiter: String, ascending: Bool) -> String {
        guard !delimiter.isEmpty else { return text }
        let lines = text.components(separatedBy: "\n")
        let sorted = lines.sorted { a, b in
            let colsA = a.components(separatedBy: delimiter)
            let colsB = b.components(separatedBy: delimiter)
            let lenA = column < colsA.count ? colsA[column].trimmingCharacters(in: .whitespaces).count : 0
            let lenB = column < colsB.count ? colsB[column].trimmingCharacters(in: .whitespaces).count : 0
            return ascending ? lenA < lenB : lenA > lenB
        }
        return sorted.joined(separator: "\n")
    }

    static func replaceText(_ text: String, search: String, replacement: String, useWildcard: Bool = false) -> String {
        guard !search.isEmpty else { return text }
        if useWildcard {
            let pattern = wildcardToRegex(search)
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return text }
            let range = NSRange(text.startIndex..., in: text)
            return regex.stringByReplacingMatches(in: text, range: range, withTemplate: NSRegularExpression.escapedTemplate(for: replacement))
        }
        return text.replacingOccurrences(of: search, with: replacement, options: .caseInsensitive)
    }

    static func extractEmails(_ text: String) -> String {
        let pattern = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        let emails = matches.compactMap { match -> String? in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range])
        }
        return emails.joined(separator: "\n")
    }

    static func sortByEmail(_ text: String, ascending: Bool) -> String {
        let pattern = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let lines = text.components(separatedBy: "\n")
        let sorted = lines.sorted { a, b in
            let emailA = firstEmail(in: a, regex: regex) ?? ""
            let emailB = firstEmail(in: b, regex: regex) ?? ""
            return ascending
                ? emailA.localizedCaseInsensitiveCompare(emailB) == .orderedAscending
                : emailA.localizedCaseInsensitiveCompare(emailB) == .orderedDescending
        }
        return sorted.joined(separator: "\n")
    }

    private static func firstEmail(in text: String, regex: NSRegularExpression) -> String? {
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let matchRange = Range(match.range, in: text) else { return nil }
        return String(text[matchRange])
    }

    static func removeBeforeSymbol(_ text: String, symbol: String) -> String {
        guard !symbol.isEmpty else { return text }
        return text.components(separatedBy: "\n")
            .map { line in
                guard let range = line.range(of: symbol, options: .caseInsensitive) else { return line }
                return String(line[range.upperBound...])
            }
            .joined(separator: "\n")
    }

    static func removeAfterSymbol(_ text: String, symbol: String) -> String {
        guard !symbol.isEmpty else { return text }
        return text.components(separatedBy: "\n")
            .map { line in
                guard let range = line.range(of: symbol, options: .caseInsensitive) else { return line }
                return String(line[..<range.lowerBound])
            }
            .joined(separator: "\n")
    }

    static func removeDuplicatesContaining(_ text: String, search: String, useWildcard: Bool = false) -> String {
        guard !search.isEmpty else { return text }
        var seen = Set<String>()
        var result: [String] = []
        for line in text.components(separatedBy: "\n") {
            if matchesPattern(line: line, pattern: search, useWildcard: useWildcard) {
                let key = line.lowercased()
                if !seen.contains(key) {
                    seen.insert(key)
                    result.append(line)
                }
            } else {
                result.append(line)
            }
        }
        return result.joined(separator: "\n")
    }

    static func removeLinesContaining(_ text: String, strings: [String], useWildcard: Bool = false, exceptions: [String] = [], clearOnly: Bool = false) -> String {
        let activeStrings = strings.filter { !$0.isEmpty }
        guard !activeStrings.isEmpty else { return text }
        let activeExceptions = exceptions.filter { !$0.isEmpty }
        return text.components(separatedBy: "\n")
            .compactMap { line -> String? in
                let matches = activeStrings.contains { matchesPattern(line: line, pattern: $0, useWildcard: useWildcard) }
                if matches && !activeExceptions.isEmpty {
                    let isException = activeExceptions.contains { matchesPattern(line: line, pattern: $0, useWildcard: useWildcard) }
                    if isException { return line }
                }
                if matches {
                    return clearOnly ? "" : nil
                }
                return line
            }
            .joined(separator: "\n")
    }

    static func removeLinesContainingAsync(_ text: String, strings: [String], useWildcard: Bool = false, exceptions: [String] = [], clearOnly: Bool = false, progress: @Sendable (Int, Int) -> Void) async -> String {
        let activeStrings = strings.filter { !$0.isEmpty }
        guard !activeStrings.isEmpty else { return text }
        let activeExceptions = exceptions.filter { !$0.isEmpty }
        let lines = text.components(separatedBy: "\n")
        let totalLines = lines.count
        let batchSize = max(500, totalLines / 100)
        var result: [String] = []
        result.reserveCapacity(totalLines)
        for batchStart in stride(from: 0, to: totalLines, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, totalLines)
            for i in batchStart..<batchEnd {
                let line = lines[i]
                let matches = activeStrings.contains { matchesPattern(line: line, pattern: $0, useWildcard: useWildcard) }
                if matches && !activeExceptions.isEmpty {
                    let isException = activeExceptions.contains { matchesPattern(line: line, pattern: $0, useWildcard: useWildcard) }
                    if isException { result.append(line); continue }
                }
                if matches {
                    if clearOnly { result.append("") }
                } else {
                    result.append(line)
                }
            }
            progress(batchEnd, totalLines)
            await Task.yield()
        }
        return result.joined(separator: "\n")
    }

    static func removeLinesNotContainingAsync(_ text: String, strings: [String], useWildcard: Bool = false, exceptions: [String] = [], progress: @Sendable (Int, Int) -> Void) async -> String {
        let activeStrings = strings.filter { !$0.isEmpty }
        guard !activeStrings.isEmpty else { return text }
        let activeExceptions = exceptions.filter { !$0.isEmpty }
        let lines = text.components(separatedBy: "\n")
        let totalLines = lines.count
        let batchSize = max(500, totalLines / 100)
        var result: [String] = []
        result.reserveCapacity(totalLines)
        for batchStart in stride(from: 0, to: totalLines, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, totalLines)
            for i in batchStart..<batchEnd {
                let line = lines[i]
                let matches = activeStrings.contains { matchesPattern(line: line, pattern: $0, useWildcard: useWildcard) }
                if !matches && !activeExceptions.isEmpty {
                    let isException = activeExceptions.contains { matchesPattern(line: line, pattern: $0, useWildcard: useWildcard) }
                    if isException { result.append(line) }
                } else if matches {
                    result.append(line)
                }
            }
            progress(batchEnd, totalLines)
            await Task.yield()
        }
        return result.joined(separator: "\n")
    }

    static func removeLinesNotContaining(_ text: String, strings: [String], useWildcard: Bool = false, exceptions: [String] = []) -> String {
        let activeStrings = strings.filter { !$0.isEmpty }
        guard !activeStrings.isEmpty else { return text }
        let activeExceptions = exceptions.filter { !$0.isEmpty }
        return text.components(separatedBy: "\n")
            .filter { line in
                let matches = activeStrings.contains { matchesPattern(line: line, pattern: $0, useWildcard: useWildcard) }
                if !matches && !activeExceptions.isEmpty {
                    let isException = activeExceptions.contains { matchesPattern(line: line, pattern: $0, useWildcard: useWildcard) }
                    return isException
                }
                return matches
            }
            .joined(separator: "\n")
    }

    static func removeLinesNoSymbolBetweenDelimiters(_ text: String, symbol: String, delimiter: String) -> String {
        guard !symbol.isEmpty, !delimiter.isEmpty else { return text }
        return text.components(separatedBy: "\n")
            .filter { line in
                let parts = line.components(separatedBy: delimiter)
                guard parts.count >= 3 else { return false }
                for i in 1..<(parts.count - 1) {
                    if parts[i].localizedCaseInsensitiveContains(symbol) {
                        return true
                    }
                }
                return false
            }
            .joined(separator: "\n")
    }

    static func removeLinesNoSymbolInColumn(_ text: String, symbol: String, column: Int, delimiter: String) -> String {
        guard !symbol.isEmpty, !delimiter.isEmpty else { return text }
        return text.components(separatedBy: "\n")
            .filter { line in
                let cols = line.components(separatedBy: delimiter)
                guard column < cols.count else { return false }
                return cols[column].localizedCaseInsensitiveContains(symbol)
            }
            .joined(separator: "\n")
    }

    static func trimLines(_ text: String) -> String {
        text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: "\n")
    }

    static func removeEmptyLines(_ text: String) -> String {
        text.components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n")
    }

    static func fixPasswordsInColumn(_ text: String, column: Int, delimiter: String, replaceWeak: Bool = false) -> String {
        guard !delimiter.isEmpty else { return text }
        return text.components(separatedBy: "\n")
            .map { line in
                var cols = line.components(separatedBy: delimiter)
                guard column < cols.count else { return line }
                var cell = cols[column]

                if !meetsPasswordRequirements(cell) {
                    cols[column] = replaceWeak ? "AAAa9998" : ""
                    return cols.joined(separator: delimiter)
                }

                let hasUppercase = cell.contains(where: { $0.isUppercase })
                if !hasUppercase {
                    if let firstLetterIndex = cell.firstIndex(where: { $0.isLetter }) {
                        let upper = cell[firstLetterIndex].uppercased()
                        cell.replaceSubrange(firstLetterIndex...firstLetterIndex, with: upper)
                        cols[column] = cell
                    }
                }

                return cols.joined(separator: delimiter)
            }
            .joined(separator: "\n")
    }

    static func removeDuplicateCellsInColumn(_ text: String, column: Int, delimiter: String) -> String {
        guard !delimiter.isEmpty else { return text }
        var seen = Set<String>()
        var result: [String] = []
        for line in text.components(separatedBy: "\n") {
            let cols = line.components(separatedBy: delimiter)
            if column < cols.count {
                let cellValue = cols[column].trimmingCharacters(in: .whitespaces).lowercased()
                if cellValue.isEmpty {
                    result.append(line)
                } else if !seen.contains(cellValue) {
                    seen.insert(cellValue)
                    result.append(line)
                }
            } else {
                result.append(line)
            }
        }
        return result.joined(separator: "\n")
    }

    static func convertLogToDualFindData(_ text: String) -> String {
        let userKeywords = ["username:", "login:", "user:", "email:"]
        let passKeywords = ["password:", "pass:"]

        let lines = text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.hasPrefix("=") && !$0.hasPrefix("-") }

        var users: [String] = []
        var passwords: [String] = []

        for line in lines {
            let lower = line.lowercased()

            if userKeywords.contains(where: { lower.contains($0) }), line.contains(":") {
                let val = line.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                if !val.isEmpty { users.append(val) }
            } else if passKeywords.contains(where: { lower.contains($0) }), line.contains(":") {
                let val = line.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                if !val.isEmpty { passwords.append(val) }
            }
        }

        var userCount: [String: Int] = [:]
        for u in users {
            let key = u.trimmingCharacters(in: .whitespaces).lowercased()
            if !key.isEmpty { userCount[key, default: 0] += 1 }
        }

        var passCount: [String: Int] = [:]
        for p in passwords {
            let key = p.trimmingCharacters(in: .whitespaces)
            if !key.isEmpty { passCount[key, default: 0] += 1 }
        }

        var output: [String] = []
        output.append("CREDENTIAL FREQUENCY REPORT")
        output.append("Total entries parsed: \(users.count + passwords.count)")
        output.append("")
        output.append(String(repeating: "=", count: 60))
        output.append("")
        output.append("USERNAMES / LOGINS / EMAILS (case-insensitive)")
        output.append("")

        let sortedUsers = userCount.sorted { $0.value > $1.value || ($0.value == $1.value && $0.key < $1.key) }
        var currentGroupCount = -1
        for (lowerName, count) in sortedUsers {
            if count != currentGroupCount {
                if currentGroupCount != -1 { output.append("") }
                currentGroupCount = count
                output.append("\(count) times:")
            }
            output.append("   \u{2022} \(lowerName)")
        }

        output.append("")
        output.append("PASSWORDS (case-sensitive)")
        output.append("")

        let sortedPasswords = passCount.sorted { $0.value > $1.value || ($0.value == $1.value && $0.key < $1.key) }
        currentGroupCount = -1
        for (pw, count) in sortedPasswords {
            if count != currentGroupCount {
                if currentGroupCount != -1 { output.append("") }
                currentGroupCount = count
                output.append("\(count) times:")
            }
            output.append("   \u{2022} \(pw)")
        }

        output.append("")
        output.append(String(repeating: "=", count: 60))
        output.append("Complete \u{2013} every username/email and every password included.")

        return output.joined(separator: "\n")
    }

    private static func meetsPasswordRequirements(_ password: String) -> Bool {
        guard password.count >= 8 else { return false }
        let hasLetter = password.contains(where: { $0.isLetter })
        let hasNumber = password.contains(where: { $0.isNumber })
        return hasLetter && hasNumber
    }

    private static func matchesPattern(line: String, pattern: String, useWildcard: Bool) -> Bool {
        if useWildcard {
            let regexPattern = wildcardToRegex(pattern)
            guard let regex = try? NSRegularExpression(pattern: regexPattern, options: .caseInsensitive) else {
                return line.localizedCaseInsensitiveContains(pattern)
            }
            let range = NSRange(line.startIndex..., in: line)
            return regex.firstMatch(in: line, range: range) != nil
        }
        return line.localizedCaseInsensitiveContains(pattern)
    }

    private static func wildcardToRegex(_ pattern: String) -> String {
        var result = ""
        for char in pattern {
            switch char {
            case "*": result += "."
            case ".": result += "\\."
            case "\\": result += "\\\\"
            case "(": result += "\\("
            case ")": result += "\\)"
            case "[": result += "\\["
            case "]": result += "\\]"
            case "{": result += "\\{"
            case "}": result += "\\}"
            case "^": result += "\\^"
            case "$": result += "\\$"
            case "|": result += "\\|"
            case "?": result += "\\?"
            case "+": result += "\\+"
            default: result.append(char)
            }
        }
        return result
    }
}
