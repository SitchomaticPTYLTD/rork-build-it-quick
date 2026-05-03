import SwiftUI

extension View {
    @ViewBuilder
    func morphGlassSurface(cornerRadius: CGFloat = 24) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            self.background(.ultraThinMaterial, in: .rect(cornerRadius: cornerRadius))
        }
    }
}
