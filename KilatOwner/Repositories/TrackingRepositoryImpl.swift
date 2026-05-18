import Foundation

protocol TrackingWebSocketTransport: AnyObject {
    func connect(url: URL) async throws
    func disconnect()
    func receive() async throws -> Data
}

final class TrackingRepositoryImpl: TrackingRepository {
    typealias TransportFactory = () -> TrackingWebSocketTransport
    typealias Sleeper = (UInt64) async throws -> Void

    private let baseURL: URL
    private let tokenStore: TokenStore?
    private let transportFactory: TransportFactory
    private let maxReconnectAttempts: Int
    private let sleep: Sleeper
    private let decoder: JSONDecoder

    init(
        baseURL: URL = URL(string: "https://api.kilat.local")!,
        session: URLSession = .shared,
        tokenStore: TokenStore? = nil,
        maxReconnectAttempts: Int = 5,
        sleep: @escaping Sleeper = { try await Task.sleep(nanoseconds: $0) }
    ) {
        self.baseURL = baseURL
        self.tokenStore = tokenStore
        self.transportFactory = { URLSessionTrackingWebSocketTransport(session: session) }
        self.maxReconnectAttempts = maxReconnectAttempts
        self.sleep = sleep
        self.decoder = Self.makeDecoder()
    }

    init(
        baseURL: URL,
        tokenStore: TokenStore?,
        transportFactory: @escaping TransportFactory,
        maxReconnectAttempts: Int = 5,
        sleep: @escaping Sleeper = { try await Task.sleep(nanoseconds: $0) },
        decoder: JSONDecoder = TrackingRepositoryImpl.makeDecoder()
    ) {
        self.baseURL = baseURL
        self.tokenStore = tokenStore
        self.transportFactory = transportFactory
        self.maxReconnectAttempts = maxReconnectAttempts
        self.sleep = sleep
        self.decoder = decoder
    }

    func subscribe(
        bookingID: String,
        onUpdate: @escaping @Sendable (TrackingEvent) -> Void,
        onDisconnect: @escaping @Sendable () -> Void
    ) -> TrackingSubscription {
        let subscription = TrackingRepositorySubscription(
            bookingID: bookingID,
            baseURL: baseURL,
            accessToken: tokenStore?.accessToken(),
            transportFactory: transportFactory,
            maxReconnectAttempts: maxReconnectAttempts,
            sleep: sleep,
            decoder: decoder,
            onUpdate: onUpdate,
            onDisconnect: onDisconnect
        )
        subscription.start()
        return subscription
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

private final class TrackingRepositorySubscription: TrackingSubscription {
    private let bookingID: String
    private let baseURL: URL
    private let accessToken: String?
    private let transportFactory: TrackingRepositoryImpl.TransportFactory
    private let maxReconnectAttempts: Int
    private let sleep: TrackingRepositoryImpl.Sleeper
    private let decoder: JSONDecoder
    private let onUpdate: @Sendable (TrackingEvent) -> Void
    private let onDisconnect: @Sendable () -> Void
    private let lock = NSLock()

    private var task: Task<Void, Never>?
    private var currentTransport: TrackingWebSocketTransport?

    init(
        bookingID: String,
        baseURL: URL,
        accessToken: String?,
        transportFactory: @escaping TrackingRepositoryImpl.TransportFactory,
        maxReconnectAttempts: Int,
        sleep: @escaping TrackingRepositoryImpl.Sleeper,
        decoder: JSONDecoder,
        onUpdate: @escaping @Sendable (TrackingEvent) -> Void,
        onDisconnect: @escaping @Sendable () -> Void
    ) {
        self.bookingID = bookingID
        self.baseURL = baseURL
        self.accessToken = accessToken
        self.transportFactory = transportFactory
        self.maxReconnectAttempts = maxReconnectAttempts
        self.sleep = sleep
        self.decoder = decoder
        self.onUpdate = onUpdate
        self.onDisconnect = onDisconnect
    }

    func start() {
        lock.lock()
        defer { lock.unlock() }

        guard task == nil else { return }
        task = Task { [weak self] in
            await self?.run()
        }
    }

    func cancel() {
        let taskToCancel: Task<Void, Never>?
        let transportToDisconnect: TrackingWebSocketTransport?

        lock.lock()
        taskToCancel = task
        task = nil
        transportToDisconnect = currentTransport
        currentTransport = nil
        lock.unlock()

        taskToCancel?.cancel()
        transportToDisconnect?.disconnect()
    }

    private func run() async {
        guard let url = Endpoints.Tracking.webSocketURL(
            baseURL: baseURL,
            bookingID: bookingID,
            accessToken: accessToken
        ) else {
            onDisconnect()
            return
        }

        var reconnectAttempt = 0

        while !Task.isCancelled {
            let transport = transportFactory()
            setCurrentTransport(transport)

            do {
                try await transport.connect(url: url)
                reconnectAttempt = 0
                try await receiveLoop(transport)
            } catch {
                guard !Task.isCancelled else { break }

                transport.disconnect()
                onDisconnect()
                reconnectAttempt += 1

                guard reconnectAttempt <= maxReconnectAttempts else {
                    break
                }

                do {
                    try await sleep(Self.backoffNanoseconds(for: reconnectAttempt))
                } catch {
                    break
                }
            }
        }

        currentTransportSnapshot()?.disconnect()
        setCurrentTransport(nil)
    }

    private func receiveLoop(_ transport: TrackingWebSocketTransport) async throws {
        while !Task.isCancelled {
            let data = try await transport.receive()
            if let event = Self.decodeEvent(from: data, using: decoder) {
                onUpdate(event)
            }
        }
    }

    private func setCurrentTransport(_ transport: TrackingWebSocketTransport?) {
        lock.lock()
        currentTransport = transport
        lock.unlock()
    }

    private func currentTransportSnapshot() -> TrackingWebSocketTransport? {
        lock.lock()
        defer { lock.unlock() }
        return currentTransport
    }

    private static func backoffNanoseconds(for attempt: Int) -> UInt64 {
        let seconds = min(pow(2.0, Double(attempt - 1)), 30)
        return UInt64(seconds * 1_000_000_000)
    }

    private static func decodeEvent(from data: Data, using decoder: JSONDecoder) -> TrackingEvent? {
        if let location = try? decoder.decode(TrackingLocationWire.self, from: data) {
            return .location(location.domain)
        }

        if let status = try? decoder.decode(BookingStatusWire.self, from: data) {
            return .status(status.domain)
        }

        return decodeEnvelopeEvent(from: data, using: decoder)
    }

    private static func decodeEnvelopeEvent(from data: Data, using decoder: JSONDecoder) -> TrackingEvent? {
        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let type = object["type"] as? String,
            let payload = object["data"],
            JSONSerialization.isValidJSONObject(payload),
            let payloadData = try? JSONSerialization.data(withJSONObject: payload)
        else {
            return nil
        }

        switch type {
        case "location", "tracking.location", "runner.position":
            guard let location = try? decoder.decode(TrackingLocationWire.self, from: payloadData) else {
                return nil
            }
            return .location(location.domain)
        case "status", "booking.status", "booking_status_changed":
            guard let status = try? decoder.decode(BookingStatusWire.self, from: payloadData) else {
                return nil
            }
            return .status(status.domain)
        default:
            return nil
        }
    }
}

private final class URLSessionTrackingWebSocketTransport: TrackingWebSocketTransport {
    private let session: URLSession
    private var task: URLSessionWebSocketTask?

    init(session: URLSession = .shared) {
        self.session = session
    }

    func connect(url: URL) async throws {
        disconnect()
        let task = session.webSocketTask(with: url)
        self.task = task
        task.resume()
    }

    func disconnect() {
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
    }

    func receive() async throws -> Data {
        guard let task else {
            throw URLError(.notConnectedToInternet)
        }

        let message = try await task.receive()
        switch message {
        case .data(let data):
            return data
        case .string(let string):
            return Data(string.utf8)
        @unknown default:
            throw URLError(.cannotDecodeContentData)
        }
    }
}

private struct TrackingLocationWire: Decodable {
    let bookingID: String
    let runnerID: String
    let latitude: Double
    let longitude: Double
    let speedKmh: Double
    let headingDegrees: Double
    let timestamp: Date

    var domain: TrackingLocationUpdate {
        TrackingLocationUpdate(
            bookingID: bookingID,
            runnerID: runnerID,
            latitude: latitude,
            longitude: longitude,
            speedKmh: speedKmh,
            headingDegrees: headingDegrees,
            timestamp: timestamp
        )
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: FlexibleCodingKey.self)
        bookingID = try container.decode(String.self, forAnyKey: "bookingID", "bookingId", "booking_id")
        runnerID = try container.decode(String.self, forAnyKey: "runnerID", "runnerId", "runner_id")
        latitude = try container.decode(Double.self, forAnyKey: "latitude", "lat")
        longitude = try container.decode(Double.self, forAnyKey: "longitude", "lng")
        speedKmh = try container.decode(Double.self, forAnyKey: "speedKmh", "speed_kmh")
        headingDegrees = try container.decode(Double.self, forAnyKey: "headingDegrees", "heading_degrees")
        timestamp = try container.decode(Date.self, forAnyKey: "timestamp")
    }
}

private struct BookingStatusWire: Decodable {
    let bookingID: String
    let oldStatus: BookingStatus?
    let newStatus: BookingStatus
    let timestamp: Date

    var domain: BookingStatusEvent {
        BookingStatusEvent(
            bookingID: bookingID,
            oldStatus: oldStatus,
            newStatus: newStatus,
            timestamp: timestamp
        )
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: FlexibleCodingKey.self)
        bookingID = try container.decode(String.self, forAnyKey: "bookingID", "bookingId", "booking_id")
        oldStatus = try container.decodeIfPresent(BookingStatus.self, forAnyKey: "oldStatus", "old_status")
        newStatus = try container.decode(BookingStatus.self, forAnyKey: "newStatus", "new_status")
        timestamp = try container.decode(Date.self, forAnyKey: "timestamp")
    }
}

private struct FlexibleCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

private extension KeyedDecodingContainer where K == FlexibleCodingKey {
    func decode<T: Decodable>(_ type: T.Type, forAnyKey keys: String...) throws -> T {
        for key in keys {
            guard let codingKey = FlexibleCodingKey(stringValue: key), contains(codingKey) else {
                continue
            }
            return try decode(type, forKey: codingKey)
        }

        throw DecodingError.keyNotFound(
            FlexibleCodingKey(stringValue: keys.first ?? "")!,
            DecodingError.Context(codingPath: codingPath, debugDescription: "Missing any of keys: \(keys)")
        )
    }

    func decodeIfPresent<T: Decodable>(_ type: T.Type, forAnyKey keys: String...) throws -> T? {
        for key in keys {
            guard let codingKey = FlexibleCodingKey(stringValue: key), contains(codingKey) else {
                continue
            }
            return try decodeIfPresent(type, forKey: codingKey)
        }

        return nil
    }
}
