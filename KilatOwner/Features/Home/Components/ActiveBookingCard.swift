import SwiftUI
import KilatUI

struct ActiveBookingCard: View {
    let booking: BookingDTO
    let onTrack: () -> Void
    let onChat: () -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Tokens.Space.md) {
                HStack(alignment: .top, spacing: Tokens.Space.md) {
                    VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                        Text("Active booking")
                            .font(Tokens.FontRole.caption)
                            .foregroundStyle(Tokens.Color.textSecondary)

                        Text(booking.petSpec.name)
                            .font(Tokens.FontRole.titleL)
                            .foregroundStyle(Tokens.Color.textPrimary)
                    }

                    Spacer(minLength: Tokens.Space.sm)

                    StatusBadge(status: booking.status.homeBadgeStatus, pulses: booking.status == .inProgress)
                }

                VStack(alignment: .leading, spacing: Tokens.Space.sm) {
                    routeRow(icon: "mappin.circle.fill", title: booking.pickupAddress.line1)
                    routeRow(icon: "flag.checkered.circle.fill", title: booking.dropoffAddress.line1)
                }

                ViewThatFits(in: .horizontal) {
                    footerRow
                    compactFooter
                }
            }
        }
    }

    private var footerRow: some View {
        HStack(spacing: Tokens.Space.sm) {
            summaryPill(icon: "clock.fill", text: booking.homeTimeLabel)
            summaryPill(icon: "creditcard.fill", text: booking.homePriceLabel)

            Spacer(minLength: Tokens.Space.xs)

            actionButtons
        }
    }

    private var compactFooter: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            HStack(spacing: Tokens.Space.sm) {
                summaryPill(icon: "clock.fill", text: booking.homeTimeLabel)
                summaryPill(icon: "creditcard.fill", text: booking.homePriceLabel)
            }

            HStack {
                Spacer()
                actionButtons
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: Tokens.Space.sm) {
            CircleBtn(icon: "message.fill", size: 42, variant: .surface, action: onChat)
            CircleBtn(icon: "location.fill", size: 42, variant: .tonal, action: onTrack)
        }
    }

    private func routeRow(icon: String, title: String) -> some View {
        HStack(spacing: Tokens.Space.sm) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Tokens.Color.primary)
                .frame(width: 22)

            Text(title)
                .font(Tokens.FontRole.body)
                .foregroundStyle(Tokens.Color.textPrimary)
                .lineLimit(1)
        }
    }

    private func summaryPill(icon: String, text: String) -> some View {
        HStack(spacing: Tokens.Space.xs) {
            Image(systemName: icon)
            Text(text)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .font(Tokens.FontRole.caption)
        .foregroundStyle(Tokens.Color.textSecondary)
        .padding(.horizontal, Tokens.Space.sm)
        .padding(.vertical, Tokens.Space.xs)
        .background(Tokens.Color.surfaceMuted)
        .clipShape(Capsule())
        .fixedSize(horizontal: true, vertical: false)
    }
}

private extension BookingStatus {
    var homeBadgeStatus: StatusBadge.Status {
        switch self {
        case .requested:
            return .pending
        case .accepted:
            return .confirmed
        case .inProgress:
            return .enroute
        case .delivered, .completed:
            return .delivered
        case .cancelled:
            return .cancelled
        }
    }
}

private extension BookingDTO {
    var homeTimeLabel: String {
        if let scheduledAt {
            return scheduledAt.formatted(date: .omitted, time: .shortened)
        }

        return "On demand"
    }

    var homePriceLabel: String {
        String(format: "RM%.2f", Double(amountCents) / 100.0)
    }
}
