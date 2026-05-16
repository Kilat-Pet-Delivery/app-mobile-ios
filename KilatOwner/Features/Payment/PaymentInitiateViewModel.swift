import Foundation
import Observation

enum PaymentPollingState: Equatable {
    case idle
    case success
    case timedOut
}

@Observable
final class PaymentInitiateViewModel {
    var redirectURL: URL?
    private(set) var isInitiating = false
    private(set) var isPolling = false
    var errorMessage: String?
    var pollingState: PaymentPollingState = .idle

    @ObservationIgnored private let paymentRepository: PaymentRepositoryProtocol
    @ObservationIgnored private let bookingRepository: BookingRepositoryProtocol

    init(
        paymentRepository: PaymentRepositoryProtocol = PaymentRepository(),
        bookingRepository: BookingRepositoryProtocol = BookingRepository()
    ) {
        self.paymentRepository = paymentRepository
        self.bookingRepository = bookingRepository
    }

    @MainActor
    func start(bookingId: String, amountCents: Int64, currency: String, email: String) async {
        isInitiating = true
        errorMessage = nil
        defer { isInitiating = false }

        do {
            redirectURL = try await paymentRepository.initiate(
                request: InitiatePaymentRequest(
                    bookingId: bookingId,
                    amountCents: amountCents,
                    currency: currency,
                    customerEmail: email
                )
            )
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    @MainActor
    func onSafariDismissed(bookingId: String) async {
        isPolling = true
        defer { isPolling = false }

        do {
            let booking = try await bookingRepository.poll(
                id: bookingId,
                intervalSec: 2,
                maxAttempts: 15
            ) { booking in
                booking.status != .awaitingPayment && booking.status != .requested
            }
            pollingState = booking.status == .awaitingPayment || booking.status == .requested ? .timedOut : .success
        } catch {
            pollingState = .timedOut
        }
    }
}
