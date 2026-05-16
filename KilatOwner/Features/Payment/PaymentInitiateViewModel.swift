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

    init(paymentRepository: PaymentRepositoryProtocol = PaymentRepository()) {
        self.paymentRepository = paymentRepository
    }

    @MainActor
    func start(bookingId: String, amountCents: Int64, currency: String, email: String) async {
        isInitiating = true
        errorMessage = nil
        defer { isInitiating = false }

        do {
            let response = try await paymentRepository.initiate(
                request: InitiatePaymentRequest(
                    bookingId: bookingId,
                    amountCents: amountCents,
                    currency: currency,
                    customerEmail: email
                )
            )
            guard let url = response.redirectURL else {
                errorMessage = "Payment unavailable — gateway did not return a redirect URL"
                return
            }
            redirectURL = url
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    // Poll the payment aggregate (NOT the booking) — escrow_status transitions to `.held`
    // once Stripe confirms the customer payment. The booking's own status stays `.requested`
    // until a runner accepts.
    @MainActor
    func onSafariDismissed(bookingId: String) async {
        isPolling = true
        defer { isPolling = false }

        do {
            let payment = try await paymentRepository.pollEscrow(
                bookingId: bookingId,
                intervalSeconds: 2,
                maxAttempts: 15
            ) { payment in
                payment.escrowStatus == .held
            }
            pollingState = payment != nil ? .success : .timedOut
        } catch {
            pollingState = .timedOut
        }
    }
}
