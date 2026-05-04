import Foundation

nonisolated struct MorphMode: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let label: String
    let icon: String
    let prompt: String

    static let presets: [MorphMode] = [
        MorphMode(
            id: "professional",
            label: "Professional",
            icon: "briefcase.fill",
            prompt: "Rewrite the following text to be professional, boardroom-ready, concise, and polished. Preserve all factual meaning."
        ),
        MorphMode(
            id: "summarize",
            label: "Summarize",
            icon: "list.bullet.rectangle.portrait.fill",
            prompt: "Summarize the following text into a clear, concise set of key points. Do not add unsupported claims."
        ),
        MorphMode(
            id: "fix",
            label: "Fix Grammar",
            icon: "sparkles",
            prompt: "Correct grammar, spelling, punctuation, and clarity while strictly maintaining the original meaning."
        ),
        MorphMode(
            id: "simplify",
            label: "Simplify",
            icon: "figure.child.circle.fill",
            prompt: "Rewrite the following text using simple language, shorter sentences, and clear structure. Preserve meaning."
        ),
        MorphMode(
            id: "expand",
            label: "Expand",
            icon: "arrow.up.left.and.arrow.down.right.circle.fill",
            prompt: "Expand the following text with relevant detail, smoother transitions, and stronger phrasing without inventing facts."
        )
    ]
}
