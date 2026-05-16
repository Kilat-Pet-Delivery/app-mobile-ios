import Foundation

protocol BookingRepositoryProtocol {
    func listAvailable() async throws -> [Booking]
    func create(request: CreateBookingRequest) async throws -> Booking
    func detail(id: String) async throws -> Booking
    func poll(id: String, intervalSec: Int, maxAttempts: Int, until: @escaping (Booking) -> Bool) async throws -> Booking
    func get(id: String) async throws -> Booking
    func accept(id: String) async throws -> Booking
    func markPickup(id: String) async throws -> Booking
    func markDelivered(id: String) async throws -> Booking
}

extension BookingRepositoryProtocol {
    func create(request: CreateBookingRequest) async throws -> Booking {
        throw NetworkError.invalidResponse
    }

    func detail(id: String) async throws -> Booking {
        try await get(id: id)
    }

    func poll(
        id: String,
        intervalSec: Int,
        maxAttempts: Int,
        until: @escaping (Booking) -> Bool
    ) async throws -> Booking {
        var latest: Booking?
        for _ in 0..<maxAttempts {
            let booking = try await detail(id: id)
            latest = booking
            if until(booking) {
                return booking
            }
            try await Task.sleep(for: .seconds(intervalSec))
        }
        if let latest {
            return latest
        }
        throw NetworkError.notFound
    }
}

final class BookingRepository: BookingRepositoryProtocol {
    private let authInterceptor: AuthInterceptor

    init(authInterceptor: AuthInterceptor) {
        self.authInterceptor = authInterceptor
    }

    convenience init(apiClient: APIClient = APIClient(), tokenStore: TokenStore = KeychainStore()) {
        self.init(authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore))
    }

    func listAvailable() async throws -> [Booking] {
        let envelope: APIResponseEnvelope<[Booking]> = try await authInterceptor.perform(.availableJobs())
        return envelope.data
    }

    func create(request: CreateBookingRequest) async throws -> Booking {
        let envelope: APIResponseEnvelope<Booking> = try await authInterceptor.perform(.createBooking, body: request)
        return envelope.data
    }

    func detail(id: String) async throws -> Booking {
        try await get(id: id)
    }

    func poll(
        id: String,
        intervalSec: Int = 2,
        maxAttempts: Int = 15,
        until: @escaping (Booking) -> Bool
    ) async throws -> Booking {
        var latest: Booking?

        for _ in 0..<maxAttempts {
            let booking = try await detail(id: id)
            latest = booking
            if until(booking) {
                return booking
            }
            try await Task.sleep(for: .seconds(intervalSec))
        }

        if let latest {
            return latest
        }
        throw NetworkError.notFound
    }

    func get(id: String) async throws -> Booking {
        let envelope: APIResponseEnvelope<Booking> = try await authInterceptor.perform(.bookingDetail(id: id))
        return envelope.data
    }

    func accept(id: String) async throws -> Booking {
        let envelope: APIResponseEnvelope<Booking> = try await authInterceptor.perform(.acceptBooking(id: id))
        return envelope.data
    }

    func markPickup(id: String) async throws -> Booking {
        let envelope: APIResponseEnvelope<Booking> = try await authInterceptor.perform(.markPickup(id: id))
        return envelope.data
    }

    func markDelivered(id: String) async throws -> Booking {
        let envelope: APIResponseEnvelope<Booking> = try await authInterceptor.perform(.markDelivered(id: id))
        return envelope.data
    }
}
