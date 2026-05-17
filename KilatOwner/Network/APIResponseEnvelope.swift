import Foundation

struct APIResponseEnvelope<Payload: Decodable>: Decodable {
    let success: Bool
    let data: Payload?
    let error: String?
    let detail: String?

    func unwrappedData() throws -> Payload {
        guard success else {
            throw APIError.serverFailure(message: error ?? detail ?? "Request failed.")
        }

        guard let data else {
            throw APIError.invalidResponse
        }

        return data
    }
}

struct PaginatedAPIResponseEnvelope<Payload: Decodable>: Decodable {
    let success: Bool
    let data: Payload?
    let pagination: Pagination?
    let error: String?
    let detail: String?

    func unwrappedData() throws -> Payload {
        guard success else {
            throw APIError.serverFailure(message: error ?? detail ?? "Request failed.")
        }

        guard let data else {
            throw APIError.invalidResponse
        }

        return data
    }
}

struct Pagination: Codable, Equatable, Sendable {
    let cursor: String?
    let nextCursor: String?
    let limit: Int?
    let total: Int?
    let page: Int?
    let totalPages: Int?
}
