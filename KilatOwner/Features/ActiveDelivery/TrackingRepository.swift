import Foundation

protocol TrackingRepositoryProtocol {
    func getHistory(bookingId: String) async throws -> [TrackingUpdate]
    func subscribe(bookingId: String, token: String) async throws -> AsyncStream<TrackingEvent>
}

final class TrackingRepository: TrackingRepositoryProtocol {
    private let authInterceptor: AuthInterceptor
    private let webSocketClient: RealtimeTrackingClient
    private let decoder: JSONDecoder

    init(
        authInterceptor: AuthInterceptor,
        webSocketClient: RealtimeTrackingClient = WebSocketClient(),
        decoder: JSONDecoder = APIClient.makeDecoderForFeatures()
    ) {
        self.authInterceptor = authInterceptor
        self.webSocketClient = webSocketClient
        self.decoder = decoder
    }

    convenience init(apiClient: APIClient = APIClient(), tokenStore: TokenStore = KeychainStore()) {
        self.init(authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore))
    }

    func getHistory(bookingId: String) async throws -> [TrackingUpdate] {
        let envelope: APIResponseEnvelope<[TrackingUpdate]> = try await authInterceptor.perform(.trackingHistory(bookingId: bookingId))
        return envelope.data
    }

    func subscribe(bookingId: String, token: String) async throws -> AsyncStream<TrackingEvent> {
        var components = URLComponents(url: AppEnvironment.wsBaseURL, resolvingAgainstBaseURL: false)
        components?.path = "/ws/tracking/\(bookingId)"
        components?.queryItems = [URLQueryItem(name: "token", value: token)]

        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }

        try await webSocketClient.connect(url: url)

        let messages = webSocketClient.messages
        let decoder = decoder

        return AsyncStream { continuation in
            Task {
                for await data in messages {
                    if let event = Self.decodeEvent(from: data, decoder: decoder) {
                        continuation.yield(event)
                    }
                }
                continuation.finish()
            }
        }
    }

    private static func decodeEvent(from data: Data, decoder: JSONDecoder) -> TrackingEvent? {
        if let update = try? decoder.decode(LocationUpdate.self, from: data) {
            return .location(update)
        }
        if let event = try? decoder.decode(BookingStatusEvent.self, from: data) {
            return .status(event)
        }
        if let envelope = try? decoder.decode(SocketEnvelope.self, from: data) {
            switch envelope.type {
            case "location", "tracking.location":
                if let update = try? decoder.decode(LocationUpdate.self, from: envelope.data) {
                    return .location(update)
                }
            case "status", "booking.status":
                if let event = try? decoder.decode(BookingStatusEvent.self, from: envelope.data) {
                    return .status(event)
                }
            default:
                return nil
            }
        }
        return nil
    }
}

private struct SocketEnvelope: Decodable {
    let type: String
    let data: Data

    enum CodingKeys: String, CodingKey {
        case type
        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        let payload = try container.decode(AnyDecodable.self, forKey: .data)
        data = try JSONSerialization.data(withJSONObject: payload.value)
    }
}

private struct AnyDecodable: Decodable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let object = try? container.decode([String: AnyDecodable].self) {
            value = object.mapValues(\.value)
        } else if let array = try? container.decode([AnyDecodable].self) {
            value = array.map(\.value)
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let number = try? container.decode(Double.self) {
            value = number
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else {
            value = NSNull()
        }
    }
}
