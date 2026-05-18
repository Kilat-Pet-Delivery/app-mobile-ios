import SwiftUI
import XCTest
@testable import KilatOwner

@MainActor
final class ForgotPasswordViewSnapshotTests: XCTestCase {
    func testForgotPasswordView_default() throws {
        let viewModel = ForgotPasswordViewModel(
            email: "owner@kilat.my",
            authRepository: StubAuthRepository()
        )

        try assertAuthSnapshot(
            ForgotPasswordView(viewModel: viewModel),
            named: "testForgotPasswordView_default"
        )
    }

    func testForgotPasswordView_loading() throws {
        let viewModel = ForgotPasswordViewModel(
            email: "owner@kilat.my",
            authRepository: StubAuthRepository()
        )
        viewModel.isLoading = true

        try assertAuthSnapshot(
            ForgotPasswordView(viewModel: viewModel),
            named: "testForgotPasswordView_loading"
        )
    }
}
