import XCTest
@testable import KilatOwner

final class APIClientTests: XCTestCase {
    private var tokenStore: InMemoryTokenStore!
    private var client: APIClient!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)

        tokenStore = InMemoryTokenStore()
        client = APIClient(
            baseURL: URL(string: "https://example.test")!,
            session: session,
            tokenStore: tokenStore
        )
    }

    override func tearDown() {
        client = nil
        tokenStore = nil
        MockURLProtocol.reset()
        super.tearDown()
    }

    func testGet_decodesEnvelope_returnsData() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/auth/profile")
            return Self.jsonResponse(request: request, body: #"{"success":true,"data":{"name":"Mei Ling"}}"#)
        }

        let payload: TestProfile = try await client.get(Endpoints.Auth.profile)

        XCTAssertEqual(payload.name, "Mei Ling")
    }

    func testGet_envelopeFailure_throwsAPIError() async {
        MockURLProtocol.requestHandler = { request in
            Self.jsonResponse(request: request, body: #"{"success":false,"error":"nope"}"#)
        }

        await XCTAssertThrowsAPIError(.serverFailure(message: "nope")) {
            let _: TestProfile = try await client.get(Endpoints.Auth.profile)
        }
    }

    func testPost_includesAuthHeader_whenTokenInKeychain() async throws {
        try tokenStore.saveAccessToken("access-token")
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            return Self.jsonResponse(request: request, body: #"{"success":true,"data":{"name":"Mei Ling"}}"#)
        }

        let _: TestProfile = try await client.post(
            Endpoints.Booking.create,
            body: TestCreateBooking(serviceID: "vet")
        )

        XCTAssertEqual(
            MockURLProtocol.capturedRequests.first?.value(forHTTPHeaderField: "Authorization"),
            "Bearer access-token"
        )
    }

    private static func jsonResponse(request: URLRequest, body: String) -> (HTTPURLResponse, Data?) {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (response, body.data(using: .utf8))
    }
}

private struct TestProfile: Decodable, Equatable {
    let name: String
}

private struct TestCreateBooking: Encodable {
    let serviceID: String
}
