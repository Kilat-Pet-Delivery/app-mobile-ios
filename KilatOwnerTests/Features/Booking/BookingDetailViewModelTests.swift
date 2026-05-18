import XCTest
@testable import KilatOwner

@MainActor
final class BookingDetailViewModelTests: XCTestCase {
    func testBookingDetailVM_status_requested_payNotInitiated_showsPayCTA() {
        let viewModel = Self.makeViewModel(
            booking: Self.booking(status: .requested, pickedUpAt: nil),
            payment: nil
        )

        XCTAssertEqual(viewModel.primaryAction, .pay)
        XCTAssertFalse(viewModel.showsCancelCTA)
        XCTAssertEqual(viewModel.paymentStatusText, "Payment not started")
    }

    func testBookingDetailVM_status_requested_payInitiated_showsPollingState() {
        let viewModel = Self.makeViewModel(
            booking: Self.booking(status: .requested, pickedUpAt: nil),
            payment: Self.payment(status: .pending),
            paymentFlowState: .polling
        )

        XCTAssertEqual(viewModel.primaryAction, .confirmingPayment)
        XCTAssertTrue(viewModel.primaryButtonIsLoading)
        XCTAssertFalse(viewModel.primaryButtonIsEnabled)
    }

    func testBookingDetailVM_status_accepted_escrowHeld_showsCancelAndTrackCTAs() {
        let viewModel = Self.makeViewModel(
            booking: Self.booking(status: .accepted, pickedUpAt: nil),
            payment: Self.payment(status: .held)
        )

        XCTAssertEqual(viewModel.primaryAction, .trackRunner)
        XCTAssertTrue(viewModel.showsCancelCTA)
    }

    func testBookingDetailVM_status_inProgress_showsTrackCTA_hidesCancelAfterPickup() {
        let viewModel = Self.makeViewModel(
            booking: Self.booking(status: .inProgress, pickedUpAt: SampleData.baseDate.addingTimeInterval(600)),
            payment: Self.payment(status: .held)
        )

        XCTAssertEqual(viewModel.primaryAction, .trackRunner)
        XCTAssertFalse(viewModel.showsCancelCTA)
    }

    func testBookingDetailVM_status_delivered_showsViewReceiptCTA() {
        let viewModel = Self.makeViewModel(
            booking: Self.booking(status: .delivered, pickedUpAt: SampleData.baseDate, deliveredAt: SampleData.baseDate.addingTimeInterval(1_800)),
            payment: Self.payment(status: .released)
        )

        XCTAssertEqual(viewModel.primaryAction, .viewReceipt)
        XCTAssertFalse(viewModel.showsCancelCTA)
    }

    func testBookingDetailVM_payTap_callsPaymentInitiate_returnsRedirectURL_opensSafariSheet() async {
        let paymentRepository = PaymentRepositoryDouble(
            initiateResponse: SampleData.paymentInitiation,
            pollResponse: Self.payment(status: .held)
        )
        let viewModel = Self.makeViewModel(
            booking: Self.booking(status: .requested, pickedUpAt: nil),
            payment: nil,
            paymentRepository: paymentRepository
        )

        await viewModel.payTapped(customerEmail: "owner@kilat.my")

        XCTAssertEqual(paymentRepository.initiateCalls.count, 1)
        XCTAssertEqual(paymentRepository.initiateCalls.first?.bookingID, SampleData.activeBookingID.uuidString)
        XCTAssertEqual(paymentRepository.initiateCalls.first?.amountCents, SampleData.activeBooking.amountCents)
        XCTAssertEqual(paymentRepository.initiateCalls.first?.customerEmail, "owner@kilat.my")
        XCTAssertEqual(viewModel.safariURL, SampleData.paymentInitiation.redirectURL)
        XCTAssertEqual(viewModel.paymentFlowState, .checkoutReady)
    }

    func testBookingDetailVM_safariDismiss_pollsEscrowUntilHeld_thenRoutesToConfirmed() async {
        let coordinator = RootCoordinator()
        let paymentRepository = PaymentRepositoryDouble(
            initiateResponse: SampleData.paymentInitiation,
            pollResponse: Self.payment(status: .held)
        )
        let viewModel = Self.makeViewModel(
            booking: Self.booking(status: .requested, pickedUpAt: nil),
            payment: Self.payment(status: .pending),
            paymentRepository: paymentRepository,
            coordinator: coordinator
        )

        await viewModel.safariDismissed()

        XCTAssertEqual(paymentRepository.pollCalls, [SampleData.activeBookingID.uuidString])
        XCTAssertEqual(viewModel.payment?.escrowStatus, .held)
        XCTAssertEqual(viewModel.paymentFlowState, .idle)
        XCTAssertEqual(coordinator.path, [.bookingConfirmed(bookingID: SampleData.activeBookingID.uuidString)])
    }

    func testBookingDetailVM_cancelTap_presentsCancelReasonSheet() {
        let viewModel = Self.makeViewModel(
            booking: Self.booking(status: .accepted, pickedUpAt: nil),
            payment: Self.payment(status: .held)
        )

        viewModel.cancelTapped()

        XCTAssertTrue(viewModel.showsCancelReasonSheet)
    }

    private static func makeViewModel(
        booking: BookingDTO,
        payment: PaymentDTO?,
        paymentFlowState: BookingDetailPaymentFlowState = .idle,
        paymentRepository: PaymentRepositoryDouble = PaymentRepositoryDouble(),
        coordinator: RootCoordinator? = nil
    ) -> BookingDetailViewModel {
        BookingDetailViewModel(
            bookingID: booking.id.uuidString,
            bookingRepository: BookingRepositoryDouble(booking: booking),
            paymentRepository: paymentRepository,
            coordinator: coordinator,
            initialBooking: booking,
            initialPayment: payment,
            paymentFlowState: paymentFlowState
        )
    }

    static func booking(
        status: BookingStatus,
        pickedUpAt: Date?,
        deliveredAt: Date? = nil
    ) -> BookingDTO {
        let base = SampleData.activeBooking
        return BookingDTO(
            id: base.id,
            bookingNumber: base.bookingNumber,
            ownerID: base.ownerID,
            runnerID: base.runnerID,
            status: status,
            petSpec: base.petSpec,
            crateRequirement: base.crateRequirement,
            pickupAddress: base.pickupAddress,
            dropoffAddress: base.dropoffAddress,
            routeSpec: base.routeSpec,
            estimatedPriceCents: base.estimatedPriceCents,
            finalPriceCents: status == .delivered ? base.estimatedPriceCents : base.finalPriceCents,
            currency: base.currency,
            scheduledAt: base.scheduledAt,
            pickedUpAt: pickedUpAt,
            deliveredAt: deliveredAt,
            cancelledAt: nil,
            cancelNote: "",
            notes: base.notes,
            version: base.version,
            createdAt: base.createdAt,
            updatedAt: deliveredAt ?? pickedUpAt ?? base.updatedAt
        )
    }

    static func payment(status: EscrowStatus) -> PaymentDTO {
        let base = SampleData.payment
        return PaymentDTO(
            id: base.id,
            bookingID: base.bookingID,
            ownerID: base.ownerID,
            runnerID: base.runnerID,
            escrowStatus: status,
            amountCents: base.amountCents,
            platformFeeCents: base.platformFeeCents,
            runnerPayoutCents: base.runnerPayoutCents,
            currency: base.currency,
            paymentMethod: base.paymentMethod,
            stripePaymentID: base.stripePaymentID,
            escrowHeldAt: status == .held ? SampleData.baseDate : nil,
            escrowReleasedAt: status == .released ? SampleData.baseDate.addingTimeInterval(2_400) : nil,
            refundedAt: status == .refunded ? SampleData.baseDate.addingTimeInterval(2_400) : nil,
            refundReason: status == .refunded ? "Owner refund" : "",
            version: base.version,
            createdAt: base.createdAt,
            updatedAt: base.updatedAt
        )
    }
}

private final class BookingRepositoryDouble: BookingRepository {
    let booking: BookingDTO

    init(booking: BookingDTO) {
        self.booking = booking
    }

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

private final class PaymentRepositoryDouble: PaymentRepository {
    struct InitiateCall: Equatable {
        let bookingID: String
        let amountCents: Int64
        let currency: String
        let customerEmail: String
    }

    let initiateResponse: InitiatePaymentResponse
    let pollResponse: PaymentDTO
    private(set) var initiateCalls: [InitiateCall]
    private(set) var pollCalls: [String]

    init(
        initiateResponse: InitiatePaymentResponse = SampleData.paymentInitiation,
        pollResponse: PaymentDTO = SampleData.payment
    ) {
        self.initiateResponse = initiateResponse
        self.pollResponse = pollResponse
        self.initiateCalls = []
        self.pollCalls = []
    }

    func initiate(
        bookingID: String,
        amountCents: Int64,
        currency: String,
        customerEmail: String
    ) async throws -> InitiatePaymentResponse {
        initiateCalls.append(
            InitiateCall(
                bookingID: bookingID,
                amountCents: amountCents,
                currency: currency,
                customerEmail: customerEmail
            )
        )
        return initiateResponse
    }

    func pollEscrow(bookingID: String) async throws -> PaymentDTO {
        pollCalls.append(bookingID)
        return pollResponse
    }
}
