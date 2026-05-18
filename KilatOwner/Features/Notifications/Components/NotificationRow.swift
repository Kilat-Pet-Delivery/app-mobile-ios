import SwiftUI
import KilatUI

struct NotificationRow: View {
    let notification: NotificationDTO
    let relativeTimestamp: String

    var body: some View {
        HStack(alignment: .top, spacing: Tokens.Space.md) {
            avatar

            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.sm) {
                    Text(notification.title)
                        .font(Tokens.FontRole.label)
                        .foregroundStyle(Tokens.Color.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: Tokens.Space.xs)

                    Text(relativeTimestamp)
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.textSecondary)
                        .lineLimit(1)
                }

                Text(notification.body)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if notification.readAt == nil {
                Circle()
                    .fill(Tokens.Color.primary)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
            }
        }
        .padding(.vertical, Tokens.Space.sm)
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)

            Image(systemName: iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(foregroundColor)
        }
        .frame(width: 44, height: 44)
    }

    private var iconName: String {
        switch notification.type {
        case .runnerAssigned:
            return "person.crop.circle.badge.checkmark"
        case .chatMessage:
            return "message.fill"
        case .trackingUpdated:
            return "location.fill"
        case .paymentEscrowHeld, .paymentFailed:
            return "creditcard.fill"
        case .bookingStatusChanged, .bookingAccepted, .bookingCompleted, .bookingCancelled:
            return "pawprint.fill"
        case .unknown:
            return "bell.fill"
        }
    }

    private var backgroundColor: Color {
        switch notification.type {
        case .paymentFailed, .bookingCancelled:
            return Color(red: 1.0, green: 0.88, blue: 0.86)
        case .chatMessage, .trackingUpdated:
            return Color(red: 0.84, green: 0.92, blue: 1.0)
        default:
            return Tokens.Color.primaryTonal
        }
    }

    private var foregroundColor: Color {
        switch notification.type {
        case .paymentFailed, .bookingCancelled:
            return Color(red: 0.72, green: 0.14, blue: 0.10)
        case .chatMessage, .trackingUpdated:
            return Color(red: 0.06, green: 0.34, blue: 0.62)
        default:
            return Tokens.Color.onPrimaryTonal
        }
    }
}
