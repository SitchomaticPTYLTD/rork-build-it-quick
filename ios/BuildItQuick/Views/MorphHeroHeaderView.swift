import SwiftUI

struct MorphHeroHeaderView: View {
    let groqConfigured: Bool
    let geminiConfigured: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.linearGradient(colors: [.indigo, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 58, height: 58)
                    Image(systemName: "wand.and.stars")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text("AI Text-Morph")
                        .font(.largeTitle.bold())
                        .minimumScaleFactor(0.72)
                    Text("Flagship text modification engine")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                ProviderStatusPill(name: "Groq", isConfigured: groqConfigured)
                ProviderStatusPill(name: "Gemini fallback", isConfigured: geminiConfigured)
                Spacer(minLength: 0)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .morphGlassSurface(cornerRadius: 28)
        .accessibilityElement(children: .combine)
    }
}
