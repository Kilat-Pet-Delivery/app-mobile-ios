import Foundation
import XCTest
@testable import KilatOwner

@MainActor
final class ForgotPasswordViewModelTests: XCTestCase {
    func testForgotPasswordVM_validEmail_callsRepo_andRoutesToResetSent() async {
        let repository = ForgotPasswordAuthRepository()
        let coordinator = RootCoordinator()
        let viewModel = ForgotPasswordViewModel(
            email: " owner@kilat.my ",
            authRepository: repository,
            coordinator: coordinator
        )

        await viewModel.submit()

        XCTAssertEqual(repository.forgotPasswordEmails, ["owner@kilat.my"])
        XCTAssertEqual(coordinator.path, [.resetSent])
        XCTAssertNil(viewModel.validationError)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testForgotPasswordVM_invalidEmail_blocksSubmit_withInlineValidationError() async {
        let repository = ForgotPasswordAuthRepository()
        let coordinator = RootCoordinator()
        let viewModel = ForgotPasswordViewModel(
            email: "not-an-email",
            authRepository: repository,
            coordinator: coordinator
        )

        await viewModel.submit()

        XCTAssertEqual(viewModel.validationError, "Enter a valid email address.")
        XCTAssertTrue(repository.forgotPasswordEmails.isEmpty)
        XCTAssertTrue(coordinator.path.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testForgotPasswordVM_unknownEmail_silentSuccess_perSecurityPattern() async {
        let repository = ForgotPasswordAuthRepository()
        let coordinator = RootCoordinator()
        let viewModel = ForgotPasswordViewModel(
            email: "unknown@kilat.my",
            authRepository: repository,
            coordinator: coordinator
        )

        await viewModel.submit()

        XCTAssertEqual(repository.forgotPasswordEmails, ["unknown@kilat.my"])
        XCTAssertEqual(coordinator.path, [.resetSent])
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
}

private final class ForgotPasswordAuthRepository: AuthRepository {
    private(set) var forgotPasswordEmails: [String] = []

    func login(email: String, password: String) async throws -> LoginResponse {
        fatalError("Not used in ForgotPasswordViewModelTests")
    }

    func register(_ request: RegisterRequest) async throws -> LoginResponse {
        fatalError("Not used in ForgotPasswordViewModelTests")
    }

    func forgotPassword(email: String) async throws {
        forgotPasswordEmails.append(email)
    }

    func resetPassword(token: String, newPassword: String) async throws {
        fatalError("Not used in ForgotPasswordViewModelTests")
    }

    func profile() async throws -> ProfileDTO {
        fatalError("Not used in ForgotPasswordViewModelTests")
    }

    func logout() async throws {
        fatalError("Not used in ForgotPasswordViewModelTests")
    }
}
