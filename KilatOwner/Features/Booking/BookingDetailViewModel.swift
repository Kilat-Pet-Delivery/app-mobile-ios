import Foundation
import Observation

enum BookingDetailPrimaryAction: Equatable, Sendable {
    case pay
    case confirmingPayment
    case waitingForRunner
    case trackRunner
    case viewReceipt
    case refunded
    case unavailable

    var title: String {
        switch self {
        case .pay:
            return "Pay"
        case .confirmingPayment:
            return "Confirming payment"
        case .waitingForRunner:
            return "Waiting for runner"
        case .trackRunner:
            return "Track runner"
        case .viewReceipt:
            return "View receipt"
        case .refunded:
            return "Refunded"
        case .unavailable:
            return "Unavailable"
        }
    }

    var icon: String {
        switch self {
        case .pay:
            return "creditcard.fill"
        case .confirmingPayment:
            return "clock.arrow.circlepath"
        case .waitingForRunner:
            return "person.crop.circle.badge.clock"
        case .trackRunner:
            return "location.fill"
        case .viewReceipt:
            return "doc.text.fill"
        case .refunded:
            return "arrow.uturn.backward.circle.fill"
        case .unavailable:
            return "exclamationmark.triangle.fill"
        }
    }

    var isEnabled: Bool {
        switch self {
        case .pay, .trackRunner, .viewReceipt:
            return true
        case .confirmingPayment, .waitingForRunner, .refunded, .unavailable:
            return false
        }
    }

    var isLoading: Bool {
        self == .confirmingPayment
    }
}

enum BookingDetailPaymentFlowState: Equatable, Sendable {
    case idle
    case initiating
    case checkoutReady
    case polling
    case failed(String)
}

@MainActor
@Observable
final class BookingDetailViewModel {
    let bookingID: String

    var booking: BookingDTO?
    var payment: PaymentDTO?
    var isLoading: Bool
    var errorMessage: String?
    var safariURL: URL?
    var showsCancelReasonSheet: Bool
    var paymentFlowState: BookingDetailPaymentFlowState

    private let bookingRepository: BookingRepository
    private let paymentRepository: PaymentRepository
    private let coordinator: RootCoordinator?
    private var hasLoaded: Bool

    init(
        bookingID: String,
        bookingRepository: BookingRepository,
        paymentRepository: PaymentRepository,
        coordinator: RootCoordinator? = nil,
        initialBooking: BookingDTO? = nil,
        initialPayment: PaymentDTO? = nil,
        paymentFlowState: BookingDetailPaymentFlowState = .idle
    ) {
        self.bookingID = bookingID
        self.bookingRepository = bookingRepository
        self.paymentRepository = paymentRepository
        self.coordinator = coordinator
        self.booking = initialBooking
        self.payment = initialPayment
        self.paymentFlowState = paymentFlowState
        self.isLoading = false
        self.safariURL = nil
        self.showsCancelReasonSheet = false
        self.hasLoaded = initialBooking != nil
    }

    var primaryAction: BookingDetailPrimaryAction {
        if paymentFlowState == .initiating || paymentFlowState == .polling {
            return .confirmingPayment
        }

        guard let booking else {
            return .unavailable
        }

        let escrowStatus = payment?.escrowStatus

        if escrowStatus == .refunded {
            return .refunded
        }

        switch booking.status {
        case .requested:
            if escrowStatus == .held {
                return .waitingForRunner
            }
            return .pay
        case .accepted:
            return escrowStatus == .held ? .trackRunner : .unavailable
        case .inProgress:
            return escrowStatus == .held ? .trackRunner : .unavailable
        case .delivered:
            return escrowStatus == .held || escrowStatus == .released ? .viewReceipt : .unavailable
        case .completed:
            return .viewReceipt
        case .cancelled:
            return .unavailable
        }
    }

    var primaryButtonTitle: String {
        primaryAction.title
    }

    var primaryButtonIcon: String {
        primaryAction.icon
    }

    var primaryButtonIsLoading: Bool {
        primaryAction.isLoading
    }

    var primaryButtonIsEnabled: Bool {
        primaryAction.isEnabled
    }

    var showsCancelCTA: Bool {
        guard let booking, payment?.escrowStatus == .held else {
            return false
        }

        switch booking.status {
        case .accepted:
            return true
        case .inProgress:
            return booking.pickedUpAt == nil
        case .requested, .delivered, .completed, .cancelled:
            return false
        }
    }

    var paymentStatusText: String {
        switch payment?.escrowStatus {
        case .pending:
            return "Payment pending"
        case .held:
            return "Escrow held"
        case .released:
            return "Escrow released"
        case .refunded:
            return "Payment refunded"
        case .failed:
            return "Payment failed"
        case nil:
            return "Payment not started"
        }
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
            hasLoaded = true
        }

        do {
            booking = try await bookingRepository.get(id: bookingID)
        } catch {
            errorMessage = userMessage(for: error)
        }
    }

    func primaryTapped(customerEmail: String = "owner@kilat.my") async {
        switch primaryAction {
        case .pay:
            await payTapped(customerEmail: customerEmail)
        case .trackRunner:
            trackTapped()
        case .viewReceipt:
            errorMessage = nil
        case .confirmingPayment, .waitingForRunner, .refunded, .unavailable:
            break
        }
    }

    func payTapped(customerEmail: String = "owner@kilat.my") async {
        guard let booking else {
            errorMessage = "Booking details are still loading."
            return
        }

        paymentFlowState = .initiating
        errorMessage = nil

        do {
            let response = try await paymentRepository.initiate(
                bookingID: booking.id.uuidString,
                amountCents: booking.amountCents,
                currency: booking.currency,
                customerEmail: customerEmail
            )

            guard let redirectURL = response.redirectURL else {
                paymentFlowState = .failed("Payment checkout is not available yet.")
                errorMessage = "Payment checkout is not available yet."
                return
            }

            safariURL = redirectURL
            paymentFlowState = .checkoutReady
        } catch {
            let message = userMessage(for: error)
            paymentFlowState = .failed(message)
            errorMessage = message
        }
    }

    func safariDismissed() async {
        safariURL = nil
        paymentFlowState = .polling
        errorMessage = nil

        do {
            let updatedPayment = try await paymentRepository.pollEscrow(bookingID: bookingID)
            payment = updatedPayment
            paymentFlowState = .idle

            if updatedPayment.escrowStatus == .held {
                coordinator?.push(.bookingConfirmed(bookingID: bookingID))
            }
        } catch {
            let message = userMessage(for: error)
            paymentFlowState = .failed(message)
            errorMessage = message
        }
    }

    func cancelTapped() {
        showsCancelReasonSheet = true
    }

    func dismissCancelSheet() {
        showsCancelReasonSheet = false
    }

    func makeCancelReasonViewModel() -> CancelReasonViewModel {
        CancelReasonViewModel(
            bookingID: bookingID,
            bookingRepository: bookingRepository
        ) { [weak self] cancelledBooking in
            self?.booking = cancelledBooking
            self?.showsCancelReasonSheet = false
            self?.errorMessage = nil
        }
    }

    func trackTapped() {
        coordinator?.push(.tracking(bookingID: bookingID))
    }

    private func userMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.userMessage
        }

        return "Something went wrong. Please try again."
    }
}
