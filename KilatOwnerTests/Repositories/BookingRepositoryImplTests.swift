import XCTest
@testable import KilatOwner

final class BookingRepositoryImplTests: XCTestCase {
    private var tokenStore: InMemoryTokenStore!
    private var repository: BookingRepositoryImpl!

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
        repository = BookingRepositoryImpl(client: client)
    }

    override func tearDown() {
        repository = nil
        tokenStore = nil
        MockURLProtocol.reset()
        super.tearDown()
    }

    func testBookingRepoImpl_create_postsRequiredFields_returnsBookingDTO() async throws {
        try tokenStore.saveAccessToken("access-token")

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/api/v1/bookings")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer access-token")

            let body = try Self.jsonBody(from: request)
            let petSpec = try XCTUnwrap(body["pet_spec"] as? [String: Any])
            XCTAssertEqual(petSpec["name"] as? String, SampleData.mochiPet.name)
            XCTAssertEqual(petSpec["pet_type"] as? String, SampleData.mochiPet.petType.rawValue)
            XCTAssertEqual(body["notes"] as? String, "Please keep the carrier covered.")

            let pickup = try XCTUnwrap(body["pickup_address"] as? [String: Any])
            XCTAssertEqual(pickup["line1"] as? String, SampleData.pickupAddress.line1)

            let dropoff = try XCTUnwrap(body["dropoff_address"] as? [String: Any])
            XCTAssertEqual(dropoff["line1"] as? String, SampleData.dropoffAddress.line1)

            return try Self.jsonResponse(request: request, value: SampleData.activeBooking)
        }

        let created = try await repository.create(
            CreateBookingRequest(
                petSpec: SampleData.mochiPet.spec,
                pickupAddress: SampleData.pickupAddress,
                dropoffAddress: SampleData.dropoffAddress,
                scheduledAt: nil,
                notes: "Please keep the carrier covered."
            )
        )

        XCTAssertEqual(created.id, SampleData.activeBookingID)
    }

    func testBookingRepoImpl_cancel_postsReason_returnsUpdatedBookingDTO() async throws {
        let bookingID = SampleData.activeBookingID.uuidString

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/api/v1/bookings/\(bookingID)/cancel")

            let body = try Self.jsonBody(from: request)
            XCTAssertEqual(body["reason"] as? String, "wrong_booking_details")

            return try Self.jsonResponse(request: request, value: Self.cancelledBooking)
        }

        let cancelled = try await repository.cancel(
            id: bookingID,
            reason: .wrongBookingDetails,
            freeText: ""
        )

        XCTAssertEqual(cancelled.status, .cancelled)
        XCTAssertEqual(cancelled.cancelNote, "wrong_booking_details")
    }

    func testBookingRepoImpl_listActive_filtersByStatusServerSide_returnsArray() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/api/v1/bookings")

            let components = try XCTUnwrap(URLComponents(url: request.url!, resolvingAgainstBaseURL: false))
            let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
            XCTAssertEqual(query["status"], "active")

            return try Self.jsonResponse(request: request, value: [SampleData.activeBooking])
        }

        let bookings = try await repository.listActive()

        XCTAssertEqual(bookings.map(\.id), [SampleData.activeBookingID])
    }

    private static var cancelledBooking: BookingDTO {
        let base = SampleData.activeBooking
        return BookingDTO(
            id: base.id,
            bookingNumber: base.bookingNumber,
            ownerID: base.ownerID,
            runnerID: base.runnerID,
            status: .cancelled,
            petSpec: base.petSpec,
            crateRequirement: base.crateRequirement,
            pickupAddress: base.pickupAddress,
            dropoffAddress: base.dropoffAddress,
            routeSpec: base.routeSpec,
            estimatedPriceCents: base.estimatedPriceCents,
            finalPriceCents: base.finalPriceCents,
            currency: base.currency,
            scheduledAt: base.scheduledAt,
            pickedUpAt: nil,
            deliveredAt: nil,
            cancelledAt: SampleData.baseDate.addingTimeInterval(3_000),
            cancelNote: "wrong_booking_details",
            notes: base.notes,
            version: base.version + 1,
            createdAt: base.createdAt,
            updatedAt: SampleData.baseDate.addingTimeInterval(3_000)
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
