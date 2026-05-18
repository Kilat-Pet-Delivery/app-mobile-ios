import Foundation

struct HomeRepositoryImpl: HomeRepository {
    enum FetchTarget: Equatable, Sendable {
        case activeBookings
        case pets
        case recentTrips
    }

    typealias ErrorLogger = (FetchTarget, Error) -> Void

    private let client: APIClient
    private let logError: ErrorLogger

    init(
        client: APIClient,
        logError: @escaping ErrorLogger = { _, _ in }
    ) {
        self.client = client
        self.logError = logError
    }

    func snapshot() async throws -> HomeSnapshot {
        async let activeBookings = load(
            Endpoints.Booking.active,
            target: .activeBookings,
            fallback: [BookingDTO]()
        )
        async let pets = load(
            Endpoints.Pets.mine,
            target: .pets,
            fallback: [PetDTO]()
        )
        async let recentTrips = load(
            Endpoints.Booking.recent,
            target: .recentTrips,
            fallback: [BookingDTO]()
        )

        return HomeSnapshot(
            activeBooking: await activeBookings.first,
            pets: await pets,
            recentTrips: await recentTrips,
            unreadNotificationCount: 0
        )
    }

    private func load<Response: Decodable>(
        _ endpoint: APIEndpoint,
        target: FetchTarget,
        fallback: Response
    ) async -> Response {
        do {
            return try await client.get(endpoint)
        } catch {
            logError(target, error)
            return fallback
        }
    }
}
