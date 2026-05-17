import Foundation

struct EmptyRequest: Encodable {}

struct EmptyResponse: Decodable, Equatable {
    init() {}
    init(from decoder: Decoder) throws {}
}

final class APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let tokenStore: TokenStore?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        baseURL: URL = URL(string: "https://api.kilat.local")!,
        session: URLSession = .shared,
        tokenStore: TokenStore? = nil,
        encoder: JSONEncoder = APIClient.makeEncoder(),
        decoder: JSONDecoder = APIClient.makeDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.tokenStore = tokenStore
        self.encoder = encoder
        self.decoder = decoder
    }

    func get<Response: Decodable>(
        _ endpoint: APIEndpoint,
        tokenOverride: String? = nil
    ) async throws -> Response {
        try await request(endpoint, body: Optional<EmptyRequest>.none, tokenOverride: tokenOverride)
    }

    func post<Body: Encodable, Response: Decodable>(
        _ endpoint: APIEndpoint,
        body: Body,
        tokenOverride: String? = nil
    ) async throws -> Response {
        try await request(endpoint, body: body, tokenOverride: tokenOverride)
    }

    func post<Response: Decodable>(
        _ endpoint: APIEndpoint,
        tokenOverride: String? = nil
    ) async throws -> Response {
        try await request(endpoint, body: Optional<EmptyRequest>.none, tokenOverride: tokenOverride)
    }

    private func request<Body: Encodable, Response: Decodable>(
        _ endpoint: APIEndpoint,
        body: Body?,
        tokenOverride: String?
    ) async throws -> Response {
        let request = try makeRequest(endpoint, body: body, tokenOverride: tokenOverride)
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            throw APIError.network(urlError.localizedDescription)
        } catch {
            throw APIError.network(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        try validate(httpResponse)

        if data.isEmpty, Response.self == EmptyResponse.self {
            return EmptyResponse() as! Response
        }

        do {
            let envelope = try decoder.decode(APIResponseEnvelope<Response>.self, from: data)
            return try envelope.unwrappedData()
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }
    }

    private func makeRequest<Body: Encodable>(
        _ endpoint: APIEndpoint,
        body: Body?,
        tokenOverride: String?
    ) throws -> URLRequest {
        let relativePath = endpoint.path.hasPrefix("/") ? String(endpoint.path.dropFirst()) : endpoint.path
        guard var components = URLComponents(
            url: baseURL.appending(path: relativePath),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.invalidURL
        }
        components.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if endpoint.requiresAuth, let token = tokenOverride ?? tokenStore?.accessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            do {
                request.httpBody = try encoder.encode(body)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                throw APIError.encoding(error.localizedDescription)
            }
        }

        return request
    }

    private func validate(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200..<300:
            return
        case 401:
            throw APIError.unauthorized
        default:
            throw APIError.serverFailure(message: HTTPURLResponse.localizedString(forStatusCode: response.statusCode))
        }
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
