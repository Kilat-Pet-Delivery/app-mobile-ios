import SwiftUI
import KilatUI

struct RunnerCard: View {
    let runner: RunnerPersona
    let etaText: String
    let speedText: String
    let statusText: String
    let connectionState: TrackingConnectionState
    let onChat: () -> Void
    let onCall: () -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Tokens.Space.lg) {
                HStack(alignment: .center, spacing: Tokens.Space.md) {
                    Avatar(
                        name: runner.fullName,
                        size: 58,
                        bg: Tokens.Color.primary,
                        fg: Tokens.Color.onPrimary
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(runner.fullName)
                            .font(Tokens.FontRole.titleL)
                            .foregroundStyle(Tokens.Color.textPrimary)
                            .lineLimit(1)

                        Text("\(runner.vehicleDescription) - \(runner.rating, specifier: "%.1f") rating")
                            .font(Tokens.FontRole.caption)
                            .foregroundStyle(Tokens.Color.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: Tokens.Space.sm)
                }

                HStack(alignment: .center, spacing: Tokens.Space.md) {
                    statusPill

                    Spacer(minLength: Tokens.Space.sm)

                    HStack(spacing: Tokens.Space.sm) {
                        CircleBtn(icon: "message.fill", size: 46, variant: .glass, action: onChat)
                        CircleBtn(icon: "phone.fill", size: 46, variant: .glass, action: onCall)
                    }
                }

                HStack(alignment: .center, spacing: Tokens.Space.lg) {
                    metric(icon: "clock.fill", title: "ETA", value: etaText)
                    metric(icon: "speedometer", title: "Speed", value: speedText)

                    Spacer(minLength: Tokens.Space.xs)
                }
            }
        }
    }

    private var statusPill: some View {
        HStack(spacing: Tokens.Space.xs) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(connectionState == .connected ? statusText : connectionState.displayText)
                .font(Tokens.FontRole.caption)
                .foregroundStyle(statusForeground)
                .lineLimit(1)
        }
        .padding(.horizontal, Tokens.Space.sm)
        .padding(.vertical, Tokens.Space.xs)
        .background(statusBackground)
        .clipShape(Capsule())
    }

    private func metric(icon: String, title: String, value: String) -> some View {
        HStack(spacing: Tokens.Space.xs) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Tokens.Color.primary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)

                Text(value)
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.textPrimary)
                    .lineLimit(1)
            }
        }
        .frame(minWidth: 94, alignment: .leading)
    }

    private var statusColor: Color {
        switch connectionState {
        case .connected:
            return Tokens.Color.primary
        case .reconnecting:
            return Color(red: 0.84, green: 0.56, blue: 0.06)
        case .disconnected:
            return Tokens.Color.textSecondary
        }
    }

    private var statusForeground: Color {
        switch connectionState {
        case .connected:
            return Tokens.Color.onPrimaryTonal
        case .reconnecting:
            return Color(red: 0.55, green: 0.34, blue: 0.02)
        case .disconnected:
            return Tokens.Color.textSecondary
        }
    }

    private var statusBackground: Color {
        switch connectionState {
        case .connected:
            return Tokens.Color.primaryTonal
        case .reconnecting:
            return Color(red: 1.0, green: 0.89, blue: 0.64)
        case .disconnected:
            return Tokens.Color.surface
        }
    }
}
