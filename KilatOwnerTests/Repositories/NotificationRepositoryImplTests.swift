import XCTest
@testable import KilatOwner

final class NotificationRepositoryImplTests: XCTestCase {
    private var tokenStore: InMemoryTokenStore!
    private var repository: NotificationRepositoryImpl!

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
        repository = NotificationRepositoryImpl(
            client: client,
            nowProvider: { SampleData.baseDate }
        )
    }

    override func tearDown() {
        repository = nil
        tokenStore = nil
        MockURLProtocol.reset()
        super.tearDown()
    }

    func testNotificationRepoImpl_list_decodesEnvelopeWithPaginationCursor() async throws {
        try tokenStore.saveAccessToken("access-token")

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/api/v1/notifications")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer access-token")

            let components = try XCTUnwrap(URLComponents(url: request.url!, resolvingAgainstBaseURL: false))
            let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
            XCTAssertEqual(query["cursor"], "cursor-1")
            XCTAssertEqual(query["limit"], "2")

            return try Self.jsonResponse(
                request: request,
                value: NotificationListDTO(
                    items: [
                        Self.notification(
                            id: "notif-1",
                            type: .runnerAssigned,
                            title: "Runner assigned"
                        )
                    ],
                    nextCursor: "cursor-2"
                )
            )
        }

        let page = try await repository.list(cursor: "cursor-1", limit: 2)

        XCTAssertEqual(page.items.map(\.id), ["notif-1"])
        XCTAssertEqual(page.items.first?.type, .runnerAssigned)
        XCTAssertEqual(page.nextCursor, "cursor-2")
    }

    func testNotificationRepoImpl_markRead_postsReadAtTimestamp() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/api/v1/notifications/notif-1/read")

            let body = try Self.jsonBody(from: request)
            XCTAssertEqual(body["read_at"] as? String, Self.iso8601.string(from: SampleData.baseDate))

            let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }

        try await repository.markRead(id: "notif-1")

        XCTAssertEqual(MockURLProtocol.capturedRequests.count, 1)
    }

    private static func notification(
        id: String,
        type: NotificationKind,
        title: String
    ) -> NotificationDTO {
        NotificationDTO(
            id: id,
            type: type,
            title: title,
            body: "Aiman is on the way.",
            createdAt: SampleData.baseDate,
            readAt: nil
        )
    }

    private static var iso8601: ISO8601DateFormatter {
        ISO8601DateFormatter()
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
