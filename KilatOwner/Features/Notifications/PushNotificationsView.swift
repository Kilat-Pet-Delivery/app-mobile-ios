import SwiftUI
import KilatUI

struct PushNotificationsView: View {
    private let notifications = PushNotificationPreviewItem.samples

    var body: some View {
        ZStack {
            lockScreenBackground

            VStack(spacing: Tokens.Space.lg) {
                statusBar

                Spacer(minLength: Tokens.Space.xl)

                clock

                Spacer(minLength: Tokens.Space.xxl)

                VStack(spacing: Tokens.Space.sm) {
                    ForEach(notifications) { notification in
                        PushNotificationBanner(notification: notification)
                    }
                }
                .padding(.horizontal, Tokens.Space.md)
                .padding(.bottom, Tokens.Space.xxl)
            }
            .frame(maxWidth: 430)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .preferredColorScheme(.dark)
    }

    private var lockScreenBackground: some View {
        ZStack {
            Color(red: 0.06, green: 0.05, blue: 0.045)
                .ignoresSafeArea()

            LockScreenRoutePattern()
                .opacity(0.86)
                .ignoresSafeArea()
        }
    }

    private var statusBar: some View {
        HStack(spacing: Tokens.Space.sm) {
            Text("Kilat")
                .font(.system(size: 14, weight: .semibold, design: .rounded))

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "cellularbars")
                Image(systemName: "wifi")
                Image(systemName: "battery.100")
            }
            .font(.system(size: 13, weight: .semibold))
        }
        .foregroundStyle(.white.opacity(0.86))
        .padding(.horizontal, Tokens.Space.lg)
        .padding(.top, Tokens.Space.md)
    }

    private var clock: some View {
        VStack(spacing: Tokens.Space.xs) {
            Text("9:41")
                .font(.system(size: 78, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text("Monday, 18 May")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.74))
                .lineLimit(1)
        }
        .padding(.top, Tokens.Space.xl)
    }
}

private struct PushNotificationPreviewItem: Identifiable {
    let id: String
    let title: String
    let body: String
    let time: String
    let accent: Color

    static let samples = [
        PushNotificationPreviewItem(
            id: "booking-accepted",
            title: "Booking accepted",
            body: "Mochi's vet run is confirmed. Aiman arrives at 9:55 AM.",
            time: "now",
            accent: Tokens.Color.primary
        ),
        PushNotificationPreviewItem(
            id: "runner-arrived",
            title: "Runner arrived",
            body: "Aiman is outside Mont Kiara Residences for pickup.",
            time: "2m",
            accent: Tokens.Color.online
        ),
        PushNotificationPreviewItem(
            id: "chat-message",
            title: "Chat message",
            body: "Aiman: I brought the soft carrier for Mochi.",
            time: "5m",
            accent: Color(red: 0.37, green: 0.66, blue: 1.0)
        )
    ]
}

private struct PushNotificationBanner: View {
    let notification: PushNotificationPreviewItem

    var body: some View {
        HStack(alignment: .top, spacing: Tokens.Space.sm) {
            KilatPawAvatar(accent: notification.accent)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.xs) {
                    Text("Kilat")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1)

                    Spacer(minLength: Tokens.Space.xs)

                    Text(notification.time)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.56))
                        .lineLimit(1)
                }

                Text(notification.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(notification.body)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Tokens.Space.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.28), radius: 20, x: 0, y: 10)
    }
}

private struct KilatPawAvatar: View {
    let accent: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.22))

            Circle()
                .stroke(accent.opacity(0.46), lineWidth: 1)

            Image(systemName: "pawprint.fill")
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 46, height: 46)
    }
}

private struct LockScreenRoutePattern: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: -20, y: size.height * 0.24))
                    path.addCurve(
                        to: CGPoint(x: size.width + 30, y: size.height * 0.46),
                        control1: CGPoint(x: size.width * 0.18, y: size.height * 0.12),
                        control2: CGPoint(x: size.width * 0.68, y: size.height * 0.58)
                    )
                }
                .stroke(
                    Color.white.opacity(0.07),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [10, 12])
                )

                Path { path in
                    path.move(to: CGPoint(x: size.width * 0.08, y: size.height + 24))
                    path.addCurve(
                        to: CGPoint(x: size.width * 0.88, y: -32),
                        control1: CGPoint(x: size.width * 0.28, y: size.height * 0.78),
                        control2: CGPoint(x: size.width * 0.66, y: size.height * 0.34)
                    )
                }
                .stroke(
                    Tokens.Color.primary.opacity(0.14),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [16, 18])
                )

                routeDot(color: Tokens.Color.primary)
                    .position(x: size.width * 0.18, y: size.height * 0.30)

                routeDot(color: Tokens.Color.online)
                    .position(x: size.width * 0.80, y: size.height * 0.18)
            }
        }
    }

    private func routeDot(color: Color) -> some View {
        Circle()
            .fill(color.opacity(0.28))
            .frame(width: 18, height: 18)
            .overlay {
                Circle()
                    .fill(color.opacity(0.74))
                    .frame(width: 7, height: 7)
            }
    }
}

#Preview {
    PushNotificationsView()
}
