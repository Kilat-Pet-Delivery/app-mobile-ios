import Foundation

enum NotificationKind: String, Codable, CaseIterable, Equatable, Sendable {
    case bookingStatusChanged = "booking_status_changed"
    case runnerAssigned = "runner_assigned"
    case chatMessage = "chat_message"
    case bookingAccepted = "booking.accepted"
    case bookingCompleted = "booking.completed"
    case bookingCancelled = "booking.cancelled"
    case paymentEscrowHeld = "payment.escrow_held"
    case paymentFailed = "payment.failed"
    case trackingUpdated = "tracking.updated"
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = NotificationKind(rawValue: rawValue) ?? .unknown
    }
}

struct NotificationDTO: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let type: NotificationKind
    let title: String
    let body: String
    let createdAt: Date
    let readAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case body
        case createdAt
        case readAt
    }
}

struct NotificationListDTO: Codable, Equatable, Sendable {
    let items: [NotificationDTO]
    let nextCursor: String
}
