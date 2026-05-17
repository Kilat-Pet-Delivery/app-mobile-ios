import Foundation

enum APIError: Error, Equatable {
    case network(String)
    case decoding(String)
    case encoding(String)
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverFailure(message: String)

    var userMessage: String {
        switch self {
        case let .network(message):
            return message.isEmpty ? "Network request failed." : message
        case let .decoding(message):
            return "Could not read server response. \(message)"
        case let .encoding(message):
            return "Could not prepare request. \(message)"
        case .invalidURL:
            return "The app could not build a valid request."
        case .invalidResponse:
            return "The server returned an unexpected response."
        case .unauthorized:
            return "Your session has expired. Please log in again."
        case let .serverFailure(message):
            return message
        }
    }
}
