import SwiftUI

struct MorphModeCarouselView: View {
    let modes: [MorphMode]
    @Binding var selectedMode: MorphMode
    let customModeIDs: Set<String>
    let onDelete: (MorphMode) -> Void
    let onCreate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Morph Style")
                    .font(.headline)
                Spacer()
                Text(selectedMode.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(modes) { mode in
                        MorphModeChipView(
                            mode: mode,
                            isSelected: selectedMode.id == mode.id,
                            isCustom: customModeIDs.contains(mode.id),
                            onSelect: { selectedMode = mode },
                            onDelete: { onDelete(mode) }
                        )
                    }

                    Button(action: onCreate) {
                        Label("Custom", systemImage: "plus.circle.fill")
                            .font(.subheadline.weight(.bold))
                            .padding(.horizontal, 16)
                            .frame(height: 48)
                            .background(Color.indigo.opacity(0.12), in: .capsule)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.indigo)
                    .accessibilityLabel("Create custom morph style")
                }
                .padding(.vertical, 2)
            }
            .contentMargins(.horizontal, 2)
        }
        .padding(18)
        .morphGlassSurface(cornerRadius: 24)
    }
}
