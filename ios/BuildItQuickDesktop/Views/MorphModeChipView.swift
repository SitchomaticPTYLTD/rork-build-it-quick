import SwiftUI

struct MorphModeChipView: View {
    let mode: MorphMode
    let isSelected: Bool
    let isCustom: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                MorphModeIconView(icon: mode.icon, size: .callout.weight(.bold))
                Text(mode.label)
                    .font(.subheadline.weight(.bold))
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(chipBackground, in: .capsule)
            .overlay {
                Capsule()
                    .strokeBorder(isSelected ? Color.white.opacity(0.25) : Color.primary.opacity(0.08), lineWidth: 1)
            }
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .contextMenu {
            if isCustom {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete Mode", systemImage: "trash")
                }
            }
        }
        .accessibilityLabel("\(mode.label) morph style")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var chipBackground: some ShapeStyle {
        isSelected ? AnyShapeStyle(Color.indigo.gradient) : AnyShapeStyle(Color(.secondarySystemGroupedBackground))
    }
}
