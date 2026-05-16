import Foundation

protocol AuthRepositoryProtocol {
    func login(email: String, password: String) async throws -> User
    func register(_ request: RegisterRequest) async throws -> User
    func refresh() async throws
    func profile() async throws -> User
    func logout()
}

extension AuthRepositoryProtocol {
    func register(_ request: RegisterRequest) async throws -> User {
        throw NetworkError.invalidResponse
    }

    func refresh() async throws {
        throw NetworkError.unauthorized
    }

    func profile() async throws -> User {
        throw NetworkError.unauthorized
    }

    func logout() {}
}

final class AuthRepository: AuthRepositoryProtocol {
    private let authInterceptor: AuthInterceptor
    private let tokenStore: TokenStore

    init(authInterceptor: AuthInterceptor, tokenStore: TokenStore) {
        self.authInterceptor = authInterceptor
        self.tokenStore = tokenStore
    }

    convenience init(apiClient: APIClient = APIClient(), tokenStore: TokenStore = KeychainStore()) {
        self.init(
            authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore),
            tokenStore: tokenStore
        )
    }

    func login(email: String, password: String) async throws -> User {
        if ProcessInfo.processInfo.environment["KILAT_LOGIN_STUB"] != nil {
            try? tokenStore.saveAccessToken("stub-access-token")
            try? tokenStore.saveRefreshToken("stub-refresh-token")
            return User(
                id: "stub-user-id",
                email: email.isEmpty ? "owner@kilat.my" : email,
                phone: "+60123456789",
                firstName: "Stub",
                lastName: "Owner",
                role: "customer",
                isVerified: true,
                avatarURL: nil,
                createdAt: Date()
            )
        }

        let envelope: APIResponseEnvelope<LoginResponse> = try await authInterceptor.perform(
            .login,
            body: LoginRequest(email: email, password: password)
        )

        try tokenStore.saveAccessToken(envelope.data.accessToken)
        try tokenStore.saveRefreshToken(envelope.data.refreshToken)

        return envelope.data.user
    }

    func register(_ request: RegisterRequest) async throws -> User {
        let envelope: APIResponseEnvelope<AuthResponse> = try await authInterceptor.perform(
            .register,
            body: request
        )

        try tokenStore.saveAccessToken(envelope.data.accessToken)
        try tokenStore.saveRefreshToken(envelope.data.refreshToken)

        return envelope.data.user
    }

    func refresh() async throws {
        guard let refreshToken = tokenStore.refreshToken() else {
            throw NetworkError.unauthorized
        }

        let envelope: APIResponseEnvelope<AuthTokenPair> = try await authInterceptor.perform(
            .refresh,
            body: RefreshTokenRequest(refreshToken: refreshToken)
        )

        try tokenStore.saveAccessToken(envelope.data.accessToken)
        try tokenStore.saveRefreshToken(envelope.data.refreshToken)
    }

    func profile() async throws -> User {
        let envelope: APIResponseEnvelope<User> = try await authInterceptor.perform(.profile)
        return envelope.data
    }

    func logout() {
        tokenStore.clear()
    }
}
