import Foundation

protocol AuthRepository {
    func login(email: String, password: String) async throws -> LoginResponse
    func register(_ request: RegisterRequest) async throws -> LoginResponse
    func forgotPassword(email: String) async throws
    func resetPassword(token: String, newPassword: String) async throws
    func profile() async throws -> ProfileDTO
    func logout() async throws
}
