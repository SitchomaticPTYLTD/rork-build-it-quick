import SwiftUI

struct MorphBackdropView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.cyan.opacity(colorScheme == .dark ? 0.18 : 0.24))
                .frame(width: 260, height: 260)
                .blur(radius: 36)
                .offset(x: -150, y: -260)

            Circle()
                .fill(Color.indigo.opacity(colorScheme == .dark ? 0.24 : 0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 42)
                .offset(x: 170, y: 90)

            Circle()
                .fill(Color.orange.opacity(colorScheme == .dark ? 0.12 : 0.16))
                .frame(width: 220, height: 220)
                .blur(radius: 48)
                .offset(x: -120, y: 340)
        }
    }

    private var backgroundColors: [Color] {
        if colorScheme == .dark {
            [Color(red: 0.04, green: 0.05, blue: 0.08), Color(red: 0.08, green: 0.09, blue: 0.16)]
        } else {
            [Color(red: 0.96, green: 0.98, blue: 1.0), Color(red: 0.92, green: 0.95, blue: 0.99)]
        }
    }
}
