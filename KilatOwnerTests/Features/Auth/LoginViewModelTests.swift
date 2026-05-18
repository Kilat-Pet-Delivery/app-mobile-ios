import Foundation
import XCTest
@testable import KilatOwner

@MainActor
final class LoginViewModelTests: XCTestCase {
    func testLoginVM_validCredentials_succeedsAndExitsLoadingState() async {
        let repository = LoginAuthRepository(result: .success(Self.loginResponse))
        let viewModel = LoginViewModel(
            email: " owner@kilat.my ",
            password: "password123",
            authRepository: repository
        )

        await viewModel.submit()

        XCTAssertEqual(repository.loginCalls, [.init(email: "owner@kilat.my", password: "password123")])
        XCTAssertEqual(viewModel.authenticatedProfile, Self.loginResponse.user)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.validationError)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoginVM_emptyEmail_setsValidationError_blocksSubmit() async {
        let repository = LoginAuthRepository(result: .success(Self.loginResponse))
        let viewModel = LoginViewModel(
            email: "   ",
            password: "password123",
            authRepository: repository
        )

        await viewModel.submit()

        XCTAssertEqual(viewModel.validationError, "Please enter your email.")
        XCTAssertTrue(repository.loginCalls.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoginVM_emptyPassword_setsValidationError_blocksSubmit() async {
        let repository = LoginAuthRepository(result: .success(Self.loginResponse))
        let viewModel = LoginViewModel(
            email: "owner@kilat.my",
            password: "",
            authRepository: repository
        )

        await viewModel.submit()

        XCTAssertEqual(viewModel.validationError, "Please enter your password.")
        XCTAssertTrue(repository.loginCalls.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoginVM_networkError_surfacesUserFacingMessage() async {
        let repository = LoginAuthRepository(result: .failure(URLError(.notConnectedToInternet)))
        let viewModel = LoginViewModel(
            email: "owner@kilat.my",
            password: "password123",
            authRepository: repository
        )

        await viewModel.submit()

        XCTAssertEqual(viewModel.errorMessage, "Unable to sign in. Check your connection and try again.")
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoginVM_serverFailure_surfacesUserFacingMessage() async {
        let repository = LoginAuthRepository(
            result: .failure(APIError.serverFailure(message: "Invalid email or password."))
        )
        let viewModel = LoginViewModel(
            email: "owner@kilat.my",
            password: "wrong-password",
            authRepository: repository
        )

        await viewModel.submit()

        XCTAssertEqual(viewModel.errorMessage, "Invalid email or password.")
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoginVM_forgotPasswordTap_pushesForgotPasswordRoute_viaCoordinator() {
        let coordinator = RootCoordinator()
        let viewModel = LoginViewModel(
            authRepository: LoginAuthRepository(result: .success(Self.loginResponse)),
            coordinator: coordinator
        )

        viewModel.forgotPasswordTapped()

        XCTAssertEqual(coordinator.path, [.forgotPassword])
    }

    private static let loginResponse = LoginResponse(
        accessToken: "access-token",
        refreshToken: "refresh-token",
        user: ProfileDTO(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000A111")!,
            email: "owner@kilat.my",
            phone: "+60123456789",
            fullName: "Mei Tan",
            role: "owner",
            isVerified: true,
            avatarURL: nil,
            createdAt: Date(timeIntervalSince1970: 1_779_080_400)
        )
    )
}

private final class LoginAuthRepository: AuthRepository {
    struct LoginCall: Equatable {
        let email: String
        let password: String
    }

    private let result: Result<LoginResponse, Error>
    private(set) var loginCalls: [LoginCall] = []

    init(result: Result<LoginResponse, Error>) {
        self.result = result
    }

    func login(email: String, password: String) async throws -> LoginResponse {
        loginCalls.append(LoginCall(email: email, password: password))
        return try result.get()
    }

    func register(_ request: RegisterRequest) async throws -> LoginResponse {
        fatalError("Not used in LoginViewModelTests")
    }

    func forgotPassword(email: String) async throws {
        fatalError("Not used in LoginViewModelTests")
    }

    func resetPassword(token: String, newPassword: String) async throws {
        fatalError("Not used in LoginViewModelTests")
    }

    func profile() async throws -> ProfileDTO {
        fatalError("Not used in LoginViewModelTests")
    }

    func logout() async throws {
        fatalError("Not used in LoginViewModelTests")
    }
}
