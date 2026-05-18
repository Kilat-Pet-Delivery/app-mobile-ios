import Foundation

struct BookingRepositoryImpl: BookingRepository {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func create(_ request: CreateBookingRequest) async throws -> BookingDTO {
        try await client.post(Endpoints.Booking.create, body: request)
    }

    func get(id: String) async throws -> BookingDTO {
        try await client.get(Endpoints.Booking.detail(id: id))
    }

    func listActive() async throws -> [BookingDTO] {
        try await client.get(Endpoints.Booking.active)
    }

    func listRecent() async throws -> [BookingDTO] {
        try await client.get(Endpoints.Booking.recent)
    }

    func cancel(id: String, reason: CancelReason, freeText: String) async throws -> BookingDTO {
        let request = CancelBookingWireRequest(reason: reason.wireReason(freeText: freeText))
        return try await client.post(Endpoints.Booking.cancel(id: id), body: request)
    }
}

private struct CancelBookingWireRequest: Encodable {
    let reason: String
}
