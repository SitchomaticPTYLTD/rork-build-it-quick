import SwiftUI

struct PatternTemplatePickerView: View {
    let templates: [PatternTemplate]
    let onSelect: (PatternTemplate) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick-start templates")
                .font(.subheadline.weight(.semibold))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(templates) { template in
                        Button {
                            onSelect(template)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: template.icon)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.indigo)
                                    Text("\(template.examples.count) ex.")
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                    Spacer(minLength: 0)
                                }
                                Text(template.name)
                                    .font(.subheadline.weight(.semibold))
                                    .multilineTextAlignment(.leading)
                                Text(template.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                            }
                            .frame(width: 220, alignment: .leading)
                            .padding(14)
                            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.indigo.opacity(0.15), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
            .contentMargins(.horizontal, 2)
        }
    }
}
