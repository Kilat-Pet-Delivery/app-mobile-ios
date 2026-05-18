import Foundation

struct HomeSnapshot: Equatable, Sendable {
    let activeBooking: BookingDTO?
    let pets: [PetDTO]
    let recentTrips: [BookingDTO]
    let unreadNotificationCount: Int
}

protocol HomeRepository {
    func snapshot() async throws -> HomeSnapshot
}
