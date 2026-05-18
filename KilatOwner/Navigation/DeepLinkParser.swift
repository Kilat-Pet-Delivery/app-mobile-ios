import Foundation

enum DeepLinkParser {
    static func route(
        for notification: NotificationDTO,
        bookingIDResolver: (NotificationDTO) -> String = { _ in SampleData.activeBookingID.uuidString }
    ) -> OwnerRoute {
        route(for: notification.type, bookingID: bookingIDResolver(notification))
    }

    static func route(for notificationKind: NotificationKind, bookingID: String) -> OwnerRoute {
        switch notificationKind {
        case .runnerAssigned:
            return .bookingConfirmed(bookingID: bookingID)
        case .chatMessage, .trackingUpdated:
            return .tracking(bookingID: bookingID)
        case .bookingStatusChanged,
             .bookingAccepted,
             .bookingCompleted,
             .bookingCancelled,
             .paymentEscrowHeld,
             .paymentFailed,
             .unknown:
            return .bookingDetail(bookingID: bookingID)
        }
    }
}
