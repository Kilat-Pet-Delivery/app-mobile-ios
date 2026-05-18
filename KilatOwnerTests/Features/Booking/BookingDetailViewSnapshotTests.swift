import SwiftUI
import XCTest
@testable import KilatOwner

@MainActor
final class BookingDetailViewSnapshotTests: XCTestCase {
    func testBookingDetailView_requestedAwaitingPayment() throws {
        let booking = BookingDetailViewModelTests.booking(status: .requested, pickedUpAt: nil)
        try assertAuthSnapshot(
            BookingDetailView(viewModel: viewModel(booking: booking, payment: nil)),
            named: "testBookingDetailView_requestedAwaitingPayment",
            size: CGSize(width: 393, height: 1280)
        )
    }

    func testBookingDetailView_acceptedHeld() throws {
        let booking = BookingDetailViewModelTests.booking(status: .accepted, pickedUpAt: nil)
        try assertAuthSnapshot(
            BookingDetailView(viewModel: viewModel(booking: booking, payment: BookingDetailViewModelTests.payment(status: .held))),
            named: "testBookingDetailView_acceptedHeld",
            size: CGSize(width: 393, height: 1280)
        )
    }

    func testBookingDetailView_delivered() throws {
        let booking = BookingDetailViewModelTests.booking(
            status: .delivered,
            pickedUpAt: SampleData.baseDate,
            deliveredAt: SampleData.baseDate.addingTimeInterval(1_800)
        )
        try assertAuthSnapshot(
            BookingDetailView(viewModel: viewModel(booking: booking, payment: BookingDetailViewModelTests.payment(status: .released))),
            named: "testBookingDetailView_delivered",
            size: CGSize(width: 393, height: 1280)
        )
    }

    private func viewModel(booking: BookingDTO, payment: PaymentDTO?) -> BookingDetailViewModel {
        BookingDetailViewModel(
            bookingID: booking.id.uuidString,
            bookingRepository: SnapshotBookingRepository(booking: booking),
            paymentRepository: SnapshotPaymentRepository(payment: payment ?? BookingDetailViewModelTests.payment(status: .held)),
            initialBooking: booking,
            initialPayment: payment
        )
    }
}

private struct SnapshotBookingRepository: BookingRepository {
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

private struct SnapshotPaymentRepository: PaymentRepository {
    let payment: PaymentDTO

    func initiate(
        bookingID: String,
        amountCents: Int64,
        currency: String,
        customerEmail: String
    ) async throws -> InitiatePaymentResponse {
        SampleData.paymentInitiation
    }

    func pollEscrow(bookingID: String) async throws -> PaymentDTO {
        payment
    }
}
