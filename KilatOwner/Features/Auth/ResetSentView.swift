import SwiftUI
import UIKit
import KilatUI

struct ResetSentView: View {
    private let coordinator: RootCoordinator?
    private let openMail: (URL) -> Void
    private let mailURL = URL(string: "message://")!

    init(
        coordinator: RootCoordinator? = nil,
        openMail: @escaping (URL) -> Void = { url in
            UIApplication.shared.open(url)
        }
    ) {
        self.coordinator = coordinator
        self.openMail = openMail
    }

    var body: some View {
        VStack(spacing: Tokens.Space.xl) {
            Spacer(minLength: Tokens.Space.xxl)

            Card {
                VStack(spacing: Tokens.Space.xl) {
                    illustration

                    VStack(spacing: Tokens.Space.sm) {
                        Text("Reset link sent")
                            .font(Tokens.FontRole.displayL)
                            .foregroundStyle(Tokens.Color.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Check your email for a secure link to create a new password.")
                            .font(Tokens.FontRole.body)
                            .foregroundStyle(Tokens.Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: Tokens.Space.sm) {
                        PrimaryButton(
                            title: "Open Mail",
                            icon: "envelope.open.fill"
                        ) {
                            openMail(mailURL)
                        }

                        SecondaryButton(title: "Back to sign in", icon: "arrow.left") {
                            coordinator?.popToRoot()
                        }
                    }
                }
                .padding(.vertical, Tokens.Space.sm)
            }
            .frame(maxWidth: 430)

            Spacer(minLength: Tokens.Space.xxl)
        }
        .padding(.horizontal, Tokens.Space.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Tokens.Color.background.ignoresSafeArea())
    }

    private var illustration: some View {
        ZStack {
            Circle()
                .fill(Tokens.Color.primaryTonal)

            Circle()
                .stroke(Tokens.Color.primary.opacity(0.18), lineWidth: 12)
                .padding(8)

            Image(systemName: "envelope.badge.shield.half.filled")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(Tokens.Color.onPrimaryTonal)
        }
        .frame(width: 112, height: 112)
        .accessibilityHidden(true)
    }
}

#Preview {
    ResetSentView(coordinator: RootCoordinator())
}
