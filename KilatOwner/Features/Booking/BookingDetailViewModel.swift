import Foundation
import Observation

// Derived from (booking.status, payment?.escrowStatus) — full table in spec rev-2 §6.6.
enum BookingPrimaryAction: Equatable {
    case pay              // requested + (no payment | pending | failed first attempt)
    case payFailed        // payment.escrow_status == .failed AND owner already attempted
    case waitingForRunner // requested + held (paid, waiting for runner accept)
    case waitingForPickup // accepted + held (runner accepted, en route to pickup)
    case trackLive        // in_progress + held
    case completed        // delivered + (held | released)
    case refunded         // any + refunded
    case errorState       // unexpected combo (e.g. accepted but no payment) — banner only
    case none
}

@Observable
final class BookingDetailViewModel {
    let bookingId: String
    private(set) var booking: Booking?
    private(set) var payment: Payment?
    private(set) var isLoading = false
    var errorMessage: String?

    var primaryAction: BookingPrimaryAction {
        Self.derivePrimaryAction(booking: booking, payment: payment)
    }

    @ObservationIgnored private let bookingRepository: BookingRepositoryProtocol
    @ObservationIgnored private let paymentRepository: PaymentRepositoryProtocol

    init(
        bookingId: String,
        bookingRepository: BookingRepositoryProtocol = BookingRepository(),
        paymentRepository: PaymentRepositoryProtocol = PaymentRepository()
    ) {
        self.bookingId = bookingId
        self.bookingRepository = bookingRepository
        self.paymentRepository = paymentRepository
    }

    @MainActor
    func onAppear() async {
        guard booking == nil else {
            return
        }
        await refresh()
    }

    // Booking and payment are independent aggregates — fetch in parallel.
    // Payment 404 is normal pre-initiate; surface as nil, not error.
    @MainActor
    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let bookingTask = bookingRepository.detail(id: bookingId)
            async let paymentTask = paymentRepository.fetchByBooking(bookingId: bookingId)
            let (b, p) = try await (bookingTask, paymentTask)
            booking = b
            payment = p
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    // Pure function — derived from the canonical CTA table in spec rev-2 §6.6.
    // Pulled out as static so it's unit-testable without instantiating the VM.
    static func derivePrimaryAction(booking: Booking?, payment: Payment?) -> BookingPrimaryAction {
        guard let booking else {
            return .none
        }

        // Refund supersedes other states from a UX perspective.
        if payment?.escrowStatus == .refunded {
            return .refunded
        }

        switch booking.status {
        case .requested:
            switch payment?.escrowStatus {
            case nil, .pending, .failed:
                return .pay
            case .held:
                return .waitingForRunner
            case .released, .refunded, .unknown:
                return .errorState
            }
        case .accepted:
            if payment?.escrowStatus == .held {
                return .waitingForPickup
            }
            return .errorState
        case .inProgress:
            if payment?.escrowStatus == .held {
                return .trackLive
            }
            return .errorState
        case .delivered:
            if payment?.escrowStatus == .held || payment?.escrowStatus == .released {
                return .completed
            }
            return .errorState
        case .unknown:
            return .none
        }
    }
}
