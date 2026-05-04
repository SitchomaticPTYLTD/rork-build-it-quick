import SwiftUI

struct MorphProcessingPickerView: View {
    @Binding var processingMode: MorphProcessingMode

    var body: some View {
        Picker("Processing Mode", selection: $processingMode) {
            ForEach(MorphProcessingMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(6)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16))
        .accessibilityLabel("Processing mode")
    }
}
