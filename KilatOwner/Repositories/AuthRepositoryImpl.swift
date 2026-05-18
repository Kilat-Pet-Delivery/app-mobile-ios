import Foundation

struct AuthRepositoryImpl: AuthRepository {
    private let client: APIClient
    private let tokenStore: TokenStore?

    init(client: APIClient, tokenStore: TokenStore? = nil) {
        self.client = client
        self.tokenStore = tokenStore
    }

    func login(email: String, password: String) async throws -> LoginResponse {
        let response: LoginResponse = try await client.post(
            Endpoints.Auth.login,
            body: LoginRequest(email: email, password: password)
        )
        try saveTokens(from: response)
        return response
    }

    func register(_ request: RegisterRequest) async throws -> LoginResponse {
        let response: LoginResponse = try await client.post(
            Endpoints.Auth.register,
            body: request
        )
        try saveTokens(from: response)
        return response
    }

    func forgotPassword(email: String) async throws {
        let _: EmptyResponse = try await client.post(
            Endpoints.Auth.forgotPassword,
            body: ForgotPasswordRequest(email: email)
        )
    }

    func resetPassword(token: String, newPassword: String) async throws {
        let _: EmptyResponse = try await client.post(
            Endpoints.Auth.resetPassword,
            body: ResetPasswordRequest(token: token, newPassword: newPassword)
        )
    }

    func profile() async throws -> ProfileDTO {
        try await client.get(Endpoints.Auth.profile)
    }

    func logout() async throws {
        let _: EmptyResponse = try await client.post(Endpoints.Auth.logout)
        tokenStore?.clear()
    }

    private func saveTokens(from response: LoginResponse) throws {
        try tokenStore?.saveAccessToken(response.accessToken)
        try tokenStore?.saveRefreshToken(response.refreshToken)
    }
}
