import Foundation

final class AuthInterceptor {
    private let apiClient: APIClient
    private let tokenStore: TokenStore
    private let refreshLock = NSLock()
    private var refreshTask: Task<AuthTokenPair, Error>?
    private var refreshTaskID: UUID?

    init(apiClient: APIClient, tokenStore: TokenStore) {
        self.apiClient = apiClient
        self.tokenStore = tokenStore
    }

    func get<Response: Decodable>(_ endpoint: APIEndpoint) async throws -> Response {
        do {
            return try await apiClient.get(endpoint)
        } catch APIError.unauthorized where endpoint.requiresAuth {
            let tokenPair = try await refreshTokens()
            return try await apiClient.get(endpoint, tokenOverride: tokenPair.accessToken)
        }
    }

    func post<Body: Encodable, Response: Decodable>(
        _ endpoint: APIEndpoint,
        body: Body
    ) async throws -> Response {
        do {
            return try await apiClient.post(endpoint, body: body)
        } catch APIError.unauthorized where endpoint.requiresAuth {
            let tokenPair = try await refreshTokens()
            return try await apiClient.post(endpoint, body: body, tokenOverride: tokenPair.accessToken)
        }
    }

    private func refreshTokens() async throws -> AuthTokenPair {
        let (task, ownedTaskID): (Task<AuthTokenPair, Error>, UUID?) = refreshLock.withLock {
            if let existing = refreshTask {
                return (existing, nil)
            }

            let newID = UUID()
            let task = Task { [apiClient, tokenStore] in
                guard let refreshToken = tokenStore.refreshToken() else {
                    tokenStore.clear()
                    throw APIError.unauthorized
                }

                do {
                    let tokenPair: AuthTokenPair = try await apiClient.post(
                        Endpoints.Auth.refresh,
                        body: RefreshTokenRequest(refreshToken: refreshToken)
                    )
                    try tokenStore.saveAccessToken(tokenPair.accessToken)
                    try tokenStore.saveRefreshToken(tokenPair.refreshToken)
                    return tokenPair
                } catch {
                    tokenStore.clear()
                    throw APIError.unauthorized
                }
            }

            refreshTask = task
            refreshTaskID = newID
            return (task, newID)
        }

        defer {
            if let ownedTaskID {
                refreshLock.withLock {
                    if refreshTaskID == ownedTaskID {
                        refreshTask = nil
                        refreshTaskID = nil
                    }
                }
            }
        }

        return try await task.value
    }
}

struct RefreshTokenRequest: Encodable {
    let refreshToken: String
}

struct AuthTokenPair: Decodable, Equatable {
    let accessToken: String
    let refreshToken: String
}

private extension NSLock {
    func withLock<T>(_ operation: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try operation()
    }
}
