import Foundation

protocol BookingRepository {
    func create(_ request: CreateBookingRequest) async throws -> BookingDTO
    func get(id: String) async throws -> BookingDTO
    func listActive() async throws -> [BookingDTO]
    func listRecent() async throws -> [BookingDTO]
    func cancel(id: String, reason: CancelReason, freeText: String) async throws -> BookingDTO
}
