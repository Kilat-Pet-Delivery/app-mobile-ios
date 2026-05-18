import SwiftUI
import XCTest
@testable import KilatOwner

@MainActor
final class LoginViewSnapshotTests: XCTestCase {
    func testLoginView_default() throws {
        let viewModel = LoginViewModel(
            email: "owner@kilat.my",
            authRepository: StubAuthRepository()
        )

        try assertAuthSnapshot(
            LoginView(viewModel: viewModel),
            named: "testLoginView_default"
        )
    }

    func testLoginView_loading() throws {
        let viewModel = LoginViewModel(
            email: "owner@kilat.my",
            password: "password123",
            authRepository: StubAuthRepository()
        )
        viewModel.isLoading = true

        try assertAuthSnapshot(
            LoginView(viewModel: viewModel),
            named: "testLoginView_loading"
        )
    }

    func testLoginView_error() throws {
        let viewModel = LoginViewModel(
            email: "owner@kilat.my",
            password: "password123",
            authRepository: StubAuthRepository()
        )
        viewModel.errorMessage = "Invalid email or password."

        try assertAuthSnapshot(
            LoginView(viewModel: viewModel),
            named: "testLoginView_error"
        )
    }
}
