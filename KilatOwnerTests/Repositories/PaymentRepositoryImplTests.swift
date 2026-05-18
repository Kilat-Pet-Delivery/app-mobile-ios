import XCTest
@testable import KilatOwner

final class PaymentRepositoryImplTests: XCTestCase {
    private var tokenStore: InMemoryTokenStore!
    private var repository: PaymentRepositoryImpl!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        tokenStore = InMemoryTokenStore()
        let client = APIClient(
            baseURL: URL(string: "https://example.test")!,
            session: session,
            tokenStore: tokenStore
        )
        repository = PaymentRepositoryImpl(
            client: client,
            pollIntervalNanoseconds: 1,
            timeoutNanoseconds: 3,
            sleep: { _ in }
        )
    }

    override func tearDown() {
        repository = nil
        tokenStore = nil
        MockURLProtocol.reset()
        super.tearDown()
    }

    func testPaymentRepoImpl_initiate_returnsRedirectURL_andPaymentIntentID() async throws {
        try tokenStore.saveAccessToken("access-token")

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/api/v1/payments/initiate")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer access-token")

            let body = try Self.jsonBody(from: request)
            XCTAssertEqual(body["booking_id"] as? String, SampleData.activeBookingID.uuidString)
            XCTAssertEqual(body["amount_cents"] as? Int, Int(SampleData.activeBooking.amountCents))
            XCTAssertEqual(body["currency"] as? String, "MYR")
            XCTAssertEqual(body["customer_email"] as? String, "owner@kilat.my")

            return try Self.jsonResponse(request: request, value: SampleData.paymentInitiation)
        }

        let response = try await repository.initiate(
            bookingID: SampleData.activeBookingID.uuidString,
            amountCents: SampleData.activeBooking.amountCents,
            currency: "MYR",
            customerEmail: "owner@kilat.my"
        )

        XCTAssertEqual(response.redirectURL, SampleData.paymentInitiation.redirectURL)
        XCTAssertEqual(response.paymentIntentID, "pi_stub_123")
    }

    func testPaymentRepoImpl_pollEscrow_returnsHeld_whenServerEventuallyReportsHeld() async throws {
        var responses = [
            Self.payment(status: .pending),
            Self.payment(status: .held)
        ]
        let sleepLog = SleepLog()
        repository = makeRepository(sleep: { duration in
            sleepLog.record(duration)
        })

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/api/v1/payments/booking/\(SampleData.activeBookingID.uuidString)")

            let payment = responses.removeFirst()
            return try Self.jsonResponse(request: request, value: payment)
        }

        let payment = try await repository.pollEscrow(bookingID: SampleData.activeBookingID.uuidString)

        XCTAssertEqual(payment.escrowStatus, .held)
        XCTAssertEqual(MockURLProtocol.capturedRequests.count, 2)
        XCTAssertEqual(sleepLog.durations, [1])
    }

    func testPaymentRepoImpl_pollEscrow_timesOutAfter60s_throwsTimeoutError() async {
        repository = makeRepository(
            pollIntervalNanoseconds: 20_000_000_000,
            timeoutNanoseconds: 60_000_000_000,
            sleep: { _ in }
        )

        MockURLProtocol.requestHandler = { request in
            try Self.jsonResponse(request: request, value: Self.payment(status: .pending))
        }

        await XCTAssertThrowsAPIError(.timeout(message: "Payment escrow polling timed out.")) {
            _ = try await repository.pollEscrow(bookingID: SampleData.activeBookingID.uuidString)
        }
        XCTAssertEqual(MockURLProtocol.capturedRequests.count, 3)
    }

    private func makeRepository(
        pollIntervalNanoseconds: UInt64 = 1,
        timeoutNanoseconds: UInt64 = 3,
        sleep: @escaping PaymentRepositoryImpl.Sleeper
    ) -> PaymentRepositoryImpl {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = APIClient(
            baseURL: URL(string: "https://example.test")!,
            session: session,
            tokenStore: tokenStore
        )
        return PaymentRepositoryImpl(
            client: client,
            pollIntervalNanoseconds: pollIntervalNanoseconds,
            timeoutNanoseconds: timeoutNanoseconds,
            sleep: sleep
        )
    }

    private static func payment(status: EscrowStatus) -> PaymentDTO {
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
            escrowReleasedAt: nil,
            refundedAt: nil,
            refundReason: "",
            version: base.version,
            createdAt: base.createdAt,
            updatedAt: base.updatedAt
        )
    }

    private static func jsonBody(from request: URLRequest) throws -> [String: Any] {
        let data = try XCTUnwrap(request.httpBody)
        let object = try JSONSerialization.jsonObject(with: data)
        return try XCTUnwrap(object as? [String: Any])
    }

    private static func jsonResponse<T: Encodable>(
        request: URLRequest,
        value: T
    ) throws -> (HTTPURLResponse, Data?) {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (response, try envelopeData(for: value))
    }

    private static func envelopeData<T: Encodable>(for value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        var data = Data(#"{"success":true,"data":"#.utf8)
        data.append(try encoder.encode(value))
        data.append(Data("}".utf8))
        return data
    }
}

private final class SleepLog {
    private let lock = NSLock()
    private var entries: [UInt64] = []

    var durations: [UInt64] {
        lock.lock()
        defer { lock.unlock() }
        return entries
    }

    func record(_ duration: UInt64) {
        lock.lock()
        entries.append(duration)
        lock.unlock()
    }
}
