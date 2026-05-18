import SwiftUI
import KilatUI

struct SplashView: View {
    var body: some View {
        VStack(spacing: Tokens.Space.xl) {
            ZStack {
                Circle()
                    .fill(Tokens.Color.primaryTonal)

                Circle()
                    .stroke(Tokens.Color.primary.opacity(0.18), lineWidth: 12)
                    .padding(8)

                Image(systemName: "pawprint.fill")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(Tokens.Color.onPrimaryTonal)
            }
            .frame(width: 112, height: 112)

            ProgressView()
                .tint(Tokens.Color.primary)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Tokens.Color.background.ignoresSafeArea())
    }
}

#Preview {
    SplashView()
}
