import Foundation

struct TrackingUpdate: Decodable, Equatable {
    let bookingId: String
    let runnerId: String
    let latitude: Double
    let longitude: Double
    let speedKmh: Double
    let headingDegrees: Double
    let timestamp: Date
}

typealias LocationUpdate = TrackingUpdate

struct BookingStatusEvent: Decodable, Equatable {
    let bookingId: String
    let oldStatus: BookingStatus?
    let newStatus: BookingStatus
    let timestamp: Date
}

enum TrackingEvent: Equatable {
    case location(LocationUpdate)
    case status(BookingStatusEvent)
}
