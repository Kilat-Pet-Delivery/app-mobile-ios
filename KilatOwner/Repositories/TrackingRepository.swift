import Foundation

struct TrackingLocationUpdate: Codable, Equatable, Sendable {
    let bookingID: String
    let runnerID: String
    let latitude: Double
    let longitude: Double
    let speedKmh: Double
    let headingDegrees: Double
    let timestamp: Date
}

struct BookingStatusEvent: Codable, Equatable, Sendable {
    let bookingID: String
    let oldStatus: BookingStatus?
    let newStatus: BookingStatus
    let timestamp: Date
}

enum TrackingEvent: Equatable, Sendable {
    case location(TrackingLocationUpdate)
    case status(BookingStatusEvent)
}

protocol TrackingSubscription {
    func cancel()
}

protocol TrackingRepository {
    func subscribe(
        bookingID: String,
        onUpdate: @escaping @Sendable (TrackingEvent) -> Void,
        onDisconnect: @escaping @Sendable () -> Void
    ) -> TrackingSubscription
}
