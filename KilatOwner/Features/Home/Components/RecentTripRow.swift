import SwiftUI
import KilatUI

struct RecentTripRow: View {
    let booking: BookingDTO

    var body: some View {
        HStack(spacing: Tokens.Space.md) {
            ZStack {
                Circle()
                    .fill(Tokens.Color.surfaceMuted)

                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(booking.petSpec.name)
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.textPrimary)

                Text(booking.dropoffAddress.line1)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .lineLimit(1)

                Text(dateText)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: Tokens.Space.sm)

            statusPill
        }
        .padding(.vertical, Tokens.Space.sm)
    }

    private var statusPill: some View {
        Text(booking.status.displayLabel)
            .font(Tokens.FontRole.caption)
            .foregroundStyle(iconColor)
            .padding(.horizontal, Tokens.Space.sm)
            .padding(.vertical, 6)
            .background(iconColor.opacity(0.12))
            .clipShape(Capsule())
    }

    private var iconName: String {
        switch booking.status {
        case .cancelled:
            return "xmark"
        case .completed, .delivered:
            return "checkmark"
        case .requested, .accepted, .inProgress:
            return "arrow.right"
        }
    }

    private var iconColor: Color {
        switch booking.status {
        case .cancelled:
            return Tokens.Color.destructive
        case .completed, .delivered:
            return Tokens.Color.online
        case .requested, .accepted, .inProgress:
            return Tokens.Color.primary
        }
    }

    private var dateText: String {
        let date = booking.deliveredAt ?? booking.pickedUpAt ?? booking.scheduledAt ?? booking.updatedAt
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}
