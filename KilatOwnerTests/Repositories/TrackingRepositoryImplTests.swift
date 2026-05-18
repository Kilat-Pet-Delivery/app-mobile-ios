import XCTest
@testable import KilatOwner

final class TrackingRepositoryImplTests: XCTestCase {
    func testTrackingRepoImpl_subscribe_emitsInitialConnected_thenUpdatesOnEachMessage() async throws {
        let tokenStore = InMemoryTokenStore(accessToken: "access-token")
        let transport = FakeTrackingWebSocketTransport()
        let eventLog = TrackingEventLog()
        let repository = TrackingRepositoryImpl(
            baseURL: URL(string: "https://example.test")!,
            tokenStore: tokenStore,
            transportFactory: { transport },
            sleep: { _ in }
        )

        let subscription = repository.subscribe(
            bookingID: "booking-1",
            onUpdate: { event in
                Task { await eventLog.record(event) }
            },
            onDisconnect: {}
        )
        defer { subscription.cancel() }

        try await waitUntil { await transport.connectedURLs.count == 1 }
        let connectedURLs = await transport.connectedURLs
        let connectedURL = try XCTUnwrap(connectedURLs.first)
        XCTAssertEqual(connectedURL.scheme, "wss")
        XCTAssertEqual(connectedURL.host, "example.test")
        XCTAssertEqual(connectedURL.path, "/ws/tracking/booking-1")
        XCTAssertEqual(
            URLComponents(url: connectedURL, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "token" })?
                .value,
            "access-token"
        )

        await transport.emit(Self.locationMessage())
        try await waitUntil { await eventLog.events.count == 1 }

        await transport.emit(Self.statusEnvelopeMessage())
        try await waitUntil { await eventLog.events.count == 2 }

        let events = await eventLog.events
        XCTAssertEqual(
            events.first,
            .location(
                TrackingLocationUpdate(
                    bookingID: "booking-1",
                    runnerID: "runner-1",
                    latitude: 3.1531,
                    longitude: 101.7114,
                    speedKmh: 21.5,
                    headingDegrees: 92,
                    timestamp: Self.timestamp
                )
            )
        )
        XCTAssertEqual(
            events.last,
            .status(
                BookingStatusEvent(
                    bookingID: "booking-1",
                    oldStatus: .accepted,
                    newStatus: .inProgress,
                    timestamp: Self.timestamp
                )
            )
        )
    }

    func testTrackingRepoImpl_disconnect_emitsDisconnected_thenAttemptsReconnect_withBackoff() async throws {
        let transport = FakeTrackingWebSocketTransport()
        let disconnectLog = DisconnectLog()
        let sleepLog = TrackingSleepLog()
        let repository = TrackingRepositoryImpl(
            baseURL: URL(string: "ws://example.test")!,
            tokenStore: nil,
            transportFactory: { transport },
            sleep: { duration in
                await sleepLog.record(duration)
            }
        )

        let subscription = repository.subscribe(
            bookingID: "booking-1",
            onUpdate: { _ in },
            onDisconnect: {
                Task { await disconnectLog.record() }
            }
        )
        defer { subscription.cancel() }

        try await waitUntil { await transport.connectedURLs.count == 1 }
        await transport.drop()

        try await waitUntil {
            let disconnectCount = await disconnectLog.count
            let sleepDurations = await sleepLog.durations
            let connectedURLCount = await transport.connectedURLs.count
            return disconnectCount == 1
                && sleepDurations == [1_000_000_000]
                && connectedURLCount == 2
        }

        let disconnectCallCount = await transport.disconnectCallCount
        XCTAssertEqual(disconnectCallCount, 1)
    }

    func testTrackingRepoImpl_cancelHandle_stopsSubscription_clean() async throws {
        let transport = FakeTrackingWebSocketTransport()
        let eventLog = TrackingEventLog()
        let repository = TrackingRepositoryImpl(
            baseURL: URL(string: "ws://example.test")!,
            tokenStore: nil,
            transportFactory: { transport },
            sleep: { _ in }
        )

        let subscription = repository.subscribe(
            bookingID: "booking-1",
            onUpdate: { event in
                Task { await eventLog.record(event) }
            },
            onDisconnect: {}
        )

        try await waitUntil { await transport.connectedURLs.count == 1 }
        subscription.cancel()
        try await waitUntil { await transport.disconnectCallCount == 1 }

        await transport.emit(Self.locationMessage())
        try await Task.sleep(nanoseconds: 50_000_000)

        let events = await eventLog.events
        XCTAssertEqual(events, [])
    }

    private static let timestamp = ISO8601DateFormatter().date(from: "2026-05-18T04:20:00Z")!

    private static func locationMessage() -> Data {
        Data(
            """
            {
              "booking_id": "booking-1",
              "runner_id": "runner-1",
              "latitude": 3.1531,
              "longitude": 101.7114,
              "speed_kmh": 21.5,
              "heading_degrees": 92,
              "timestamp": "2026-05-18T04:20:00Z"
            }
            """.utf8
        )
    }

    private static func statusEnvelopeMessage() -> Data {
        Data(
            """
            {
              "type": "booking.status",
              "data": {
                "bookingId": "booking-1",
                "oldStatus": "accepted",
                "newStatus": "in_progress",
                "timestamp": "2026-05-18T04:20:00Z"
              }
            }
            """.utf8
        )
    }

    private func waitUntil(
        timeoutNanoseconds: UInt64 = 1_000_000_000,
        condition: @escaping () async -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(Double(timeoutNanoseconds) / 1_000_000_000)
        while Date() < deadline {
            if await condition() { return }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("Timed out waiting for condition.")
    }
}

private actor TrackingEventLog {
    private(set) var events: [TrackingEvent] = []

    func record(_ event: TrackingEvent) {
        events.append(event)
    }
}

private actor DisconnectLog {
    private(set) var count = 0

    func record() {
        count += 1
    }
}

private actor TrackingSleepLog {
    private(set) var durations: [UInt64] = []

    func record(_ duration: UInt64) {
        durations.append(duration)
    }
}

private final class FakeTrackingWebSocketTransport: TrackingWebSocketTransport {
    private let core = FakeTrackingWebSocketCore()

    var connectedURLs: [URL] {
        get async { await core.connectedURLs }
    }

    var disconnectCallCount: Int {
        get async { await core.disconnectCallCount }
    }

    func connect(url: URL) async throws {
        await core.connect(url: url)
    }

    func disconnect() {
        Task { await core.disconnect() }
    }

    func receive() async throws -> Data {
        try await core.receive()
    }

    func emit(_ data: Data) async {
        await core.emit(data)
    }

    func drop() async {
        await core.drop()
    }
}

private actor FakeTrackingWebSocketCore {
    private(set) var connectedURLs: [URL] = []
    private(set) var disconnectCallCount = 0
    private var pendingResults: [Result<Data, Error>] = []
    private var receiveContinuation: CheckedContinuation<Data, Error>?

    func connect(url: URL) {
        connectedURLs.append(url)
    }

    func disconnect() {
        disconnectCallCount += 1
        if let continuation = receiveContinuation {
            receiveContinuation = nil
            continuation.resume(throwing: CancellationError())
        }
    }

    func receive() async throws -> Data {
        if !pendingResults.isEmpty {
            return try pendingResults.removeFirst().get()
        }

        return try await withCheckedThrowingContinuation { continuation in
            receiveContinuation = continuation
        }
    }

    func emit(_ data: Data) {
        deliver(.success(data))
    }

    func drop() {
        deliver(.failure(URLError(.networkConnectionLost)))
    }

    private func deliver(_ result: Result<Data, Error>) {
        if let continuation = receiveContinuation {
            receiveContinuation = nil
            continuation.resume(with: result)
        } else {
            pendingResults.append(result)
        }
    }
}
