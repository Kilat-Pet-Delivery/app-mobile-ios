import SwiftUI
import XCTest
@testable import KilatOwner

@MainActor
final class BookingConfirmedViewSnapshotTests: XCTestCase {
    func testBookingConfirmedView_default() throws {
        let booking = BookingConfirmedViewModelTests.booking(etaMinutes: 8)

        try assertAuthSnapshot(
            BookingConfirmedView(viewModel: viewModel(booking: booking)),
            named: "testBookingConfirmedView_default",
            size: CGSize(width: 393, height: 900)
        )
    }

    func testBookingConfirmedView_lateRunner() throws {
        let booking = BookingConfirmedViewModelTests.booking(etaMinutes: 14)

        try assertAuthSnapshot(
            BookingConfirmedView(viewModel: viewModel(booking: booking)),
            named: "testBookingConfirmedView_lateRunner",
            size: CGSize(width: 393, height: 900)
        )
    }

    private func viewModel(booking: BookingDTO) -> BookingConfirmedViewModel {
        BookingConfirmedViewModel(
            bookingID: booking.id.uuidString,
            booking: booking,
            bookingRepository: BookingConfirmedSnapshotRepository(booking: booking)
        )
    }
}

private struct BookingConfirmedSnapshotRepository: BookingRepository {
    let booking: BookingDTO

    func create(_ request: CreateBookingRequest) async throws -> BookingDTO {
        booking
    }

    func get(id: String) async throws -> BookingDTO {
        booking
    }

    func listActive() async throws -> [BookingDTO] {
        [booking]
    }

    func listRecent() async throws -> [BookingDTO] {
        [booking]
    }

    func cancel(id: String, reason: CancelReason, freeText: String) async throws -> BookingDTO {
        booking
    }
}
