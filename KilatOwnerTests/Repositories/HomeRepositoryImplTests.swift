import XCTest
@testable import KilatOwner

final class HomeRepositoryImplTests: XCTestCase {
    private var tokenStore: InMemoryTokenStore!
    private var client: APIClient!
    private var repository: HomeRepositoryImpl!

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
        repository = HomeRepositoryImpl(client: client)
    }

    override func tearDown() {
        repository = nil
        client = nil
        tokenStore = nil
        MockURLProtocol.reset()
        super.tearDown()
    }

    func testHomeRepoImpl_snapshot_parallelFetches_combinesIntoSingleResult() async throws {
        try tokenStore.saveAccessToken("access-token")
        let requestLog = RequestLog()

        MockURLProtocol.requestHandler = { request in
            requestLog.record(request)

            switch try Self.route(for: request) {
            case .activeBookings:
                return try Self.jsonResponse(request: request, value: [SampleData.activeBooking])
            case .pets:
                return try Self.jsonResponse(request: request, value: [SampleData.mochiPet, SampleData.baoPet])
            case .recentTrips:
                return try Self.jsonResponse(request: request, value: [SampleData.completedBooking])
            }
        }

        let snapshot = try await repository.snapshot()

        XCTAssertEqual(snapshot.activeBooking?.id, SampleData.activeBookingID)
        XCTAssertEqual(snapshot.pets.map(\.id), [SampleData.mochiID, SampleData.baoID])
        XCTAssertEqual(snapshot.recentTrips.map(\.id), [SampleData.completedBookingID])
        XCTAssertEqual(snapshot.unreadNotificationCount, 0)
        XCTAssertEqual(
            requestLog.routes.sorted(),
            [Route.activeBookings.rawValue, Route.pets.rawValue, Route.recentTrips.rawValue].sorted()
        )
        XCTAssertEqual(
            requestLog.authorizationHeaders,
            ["Bearer access-token", "Bearer access-token", "Bearer access-token"]
        )
    }

    func testHomeRepoImpl_snapshot_oneEndpointFails_returnsPartialDataAndLogsError() async throws {
        let errorLog = ErrorLog()
        repository = HomeRepositoryImpl(client: client) { target, error in
            errorLog.record(target: target, error: error)
        }

        MockURLProtocol.requestHandler = { request in
            switch try Self.route(for: request) {
            case .activeBookings:
                return try Self.jsonResponse(request: request, value: [SampleData.activeBooking])
            case .pets:
                return Self.jsonError(request: request, statusCode: 500)
            case .recentTrips:
                return try Self.jsonResponse(request: request, value: [SampleData.completedBooking])
            }
        }

        let snapshot = try await repository.snapshot()

        XCTAssertEqual(snapshot.activeBooking?.id, SampleData.activeBookingID)
        XCTAssertTrue(snapshot.pets.isEmpty)
        XCTAssertEqual(snapshot.recentTrips.map(\.id), [SampleData.completedBookingID])
        XCTAssertEqual(errorLog.targets, [.pets])
        XCTAssertEqual(errorLog.count, 1)
    }

    fileprivate static func route(for request: URLRequest) throws -> Route {
        guard
            let url = request.url,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            throw APIError.invalidURL
        }

        if components.path == "/api/v1/users/me/pets" {
            return .pets
        }

        let query = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
                item.value.map { (item.name, $0) }
            }
        )

        if components.path == "/api/v1/bookings", query["status"] == "active" {
            return .activeBookings
        }

        if components.path == "/api/v1/bookings", query["status"] == "completed", query["limit"] == "5" {
            return .recentTrips
        }

        throw APIError.invalidURL
    }

    private static func jsonResponse<T: Encodable>(
        request: URLRequest,
        value: T
    ) throws -> (HTTPURLResponse, Data?) {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (response, try envelopeData(for: value))
    }

    private static func jsonError(
        request: URLRequest,
        statusCode: Int
    ) -> (HTTPURLResponse, Data?) {
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        return (response, #"{"success":false,"error":"Request failed"}"#.data(using: .utf8))
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

private enum Route: String {
    case activeBookings
    case pets
    case recentTrips
}

private final class RequestLog {
    private let lock = NSLock()
    private var entries: [(route: String, authorizationHeader: String?)] = []

    var routes: [String] {
        lock.lock()
        defer { lock.unlock() }
        return entries.map(\.route)
    }

    var authorizationHeaders: [String?] {
        lock.lock()
        defer { lock.unlock() }
        return entries.map(\.authorizationHeader)
    }

    func record(_ request: URLRequest) {
        let route = (try? HomeRepositoryImplTests.route(for: request).rawValue) ?? "unknown"
        lock.lock()
        entries.append((route: route, authorizationHeader: request.value(forHTTPHeaderField: "Authorization")))
        lock.unlock()
    }
}

private final class ErrorLog {
    private let lock = NSLock()
    private var entries: [(target: HomeRepositoryImpl.FetchTarget, error: Error)] = []

    var targets: [HomeRepositoryImpl.FetchTarget] {
        lock.lock()
        defer { lock.unlock() }
        return entries.map(\.target)
    }

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return entries.count
    }

    func record(target: HomeRepositoryImpl.FetchTarget, error: Error) {
        lock.lock()
        entries.append((target: target, error: error))
        lock.unlock()
    }
}
