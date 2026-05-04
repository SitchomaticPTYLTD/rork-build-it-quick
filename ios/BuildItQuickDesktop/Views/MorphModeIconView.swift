import SwiftUI

struct MorphModeIconView: View {
    let icon: String
    let size: Font

    init(icon: String, size: Font = .title3) {
        self.icon = icon
        self.size = size
    }

    var body: some View {
        if icon.contains(".") || icon.contains("-") {
            Image(systemName: icon)
                .font(size)
                .symbolRenderingMode(.hierarchical)
        } else {
            Text(icon)
                .font(size)
        }
    }
}
