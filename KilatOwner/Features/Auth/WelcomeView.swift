import SwiftUI
import KilatUI

@MainActor
enum WelcomeActions {
    static func bookFirstRun(coordinator: RootCoordinator?) {
        coordinator?.popToRoot()
        coordinator?.push(.home)
        coordinator?.push(.services(prefilledPetID: nil))
    }
}

struct WelcomeView: View {
    private let coordinator: RootCoordinator?

    init(coordinator: RootCoordinator? = nil) {
        self.coordinator = coordinator
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.xl) {
                header
                actions
            }
            .padding(.horizontal, Tokens.Space.lg)
            .padding(.vertical, Tokens.Space.xxl)
            .frame(maxWidth: 430)
            .frame(maxWidth: .infinity)
        }
        .background(Tokens.Color.background.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.lg) {
            ZStack {
                Circle()
                    .fill(Tokens.Color.primaryTonal)

                Circle()
                    .stroke(Tokens.Color.primary.opacity(0.18), lineWidth: 12)
                    .padding(8)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(Tokens.Color.onPrimaryTonal)
            }
            .frame(width: 112, height: 112)

            VStack(alignment: .leading, spacing: Tokens.Space.sm) {
                Text("Account ready!")
                    .font(Tokens.FontRole.displayL)
                    .foregroundStyle(Tokens.Color.textPrimary)

                Text("You can book a pet delivery, add another pet, or browse services whenever you are ready.")
                    .font(Tokens.FontRole.body)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var actions: some View {
        VStack(spacing: Tokens.Space.md) {
            actionCard(
                title: "Book your first run",
                subtitle: "Choose your pet and service.",
                icon: "figure.run",
                isPrimary: true
            ) {
                WelcomeActions.bookFirstRun(coordinator: coordinator)
            }

            actionCard(
                title: "Add another pet",
                subtitle: "Keep pet details ready for future trips.",
                icon: "pawprint.fill"
            ) {
                coordinator?.push(.home)
            }

            actionCard(
                title: "Browse services",
                subtitle: "See vet, grooming, boarding, and more.",
                icon: "square.grid.2x2.fill"
            ) {
                coordinator?.push(.services(prefilledPetID: nil))
            }
        }
    }

    private func actionCard(
        title: String,
        subtitle: String,
        icon: String,
        isPrimary: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Card {
                HStack(spacing: Tokens.Space.md) {
                    ZStack {
                        Circle()
                            .fill(isPrimary ? Tokens.Color.primary : Tokens.Color.primaryTonal)

                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(isPrimary ? Tokens.Color.onPrimary : Tokens.Color.onPrimaryTonal)
                    }
                    .frame(width: 56, height: 56)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(Tokens.FontRole.label)
                            .foregroundStyle(Tokens.Color.textPrimary)

                        Text(subtitle)
                            .font(Tokens.FontRole.caption)
                            .foregroundStyle(Tokens.Color.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: Tokens.Space.sm)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Tokens.Color.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WelcomeView(coordinator: RootCoordinator())
}
