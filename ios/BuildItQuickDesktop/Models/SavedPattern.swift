import Foundation

nonisolated struct SavedPattern: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: UUID
    var name: String
    var rule: String
    var confidence: Int
    var examples: [ExamplePair]
    var refinement: String
    var createdAt: Date
    var lastUsedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        rule: String,
        confidence: Int,
        examples: [ExamplePair],
        refinement: String = "",
        createdAt: Date = Date(),
        lastUsedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.rule = rule
        self.confidence = confidence
        self.examples = examples
        self.refinement = refinement
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }
}

nonisolated struct PatternTemplate: Identifiable, Sendable {
    let id: String
    let name: String
    let icon: String
    let summary: String
    let examples: [ExamplePair]

    static let library: [PatternTemplate] = [
        PatternTemplate(
            id: "credential-grouping",
            name: "Group credentials by email",
            icon: "person.crop.rectangle.stack.fill",
            summary: "Merge duplicate email/password pairs into a single comma-separated row.",
            examples: [
                ExamplePair(
                    before: "sonnyw96@yahoo.com;winteRs6619!\nsonnyw96@yahoo.com;wanders537\nsonnyw96@yahoo.com;Winters99",
                    after: "sonnyw96@yahoo.com,winteRs6619!,wanders537,Winters99"
                ),
                ExamplePair(
                    before: "sterny666@gmail.com;swidgen13\nsterny666@gmail.com;Sterny991\nsterny666@gmail.com;swidgen1",
                    after: "sterny666@gmail.com,swidgen13,Sterny991,swidgen1"
                )
            ]
        ),
        PatternTemplate(
            id: "date-standardize",
            name: "Standardize dates",
            icon: "calendar.badge.clock",
            summary: "Normalize any date format to long-form English.",
            examples: [
                ExamplePair(before: "Meeting on 05/12/2025 at 3pm", after: "Meeting on December 5, 2025 at 3:00 PM"),
                ExamplePair(before: "Deadline: 12-05-2025", after: "Deadline: December 5, 2025"),
                ExamplePair(before: "Event: 2025-12-05", after: "Event: December 5, 2025")
            ]
        ),
        PatternTemplate(
            id: "list-renumber",
            name: "Bullets → numbered list",
            icon: "list.number",
            summary: "Convert bulleted lists into numbered lists.",
            examples: [
                ExamplePair(before: "* Buy milk\n* Walk dog\n* Call mom", after: "1. Buy milk\n2. Walk dog\n3. Call mom")
            ]
        )
    ]
}
