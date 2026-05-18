import SwiftUI
import XCTest
@testable import KilatOwner

@MainActor
final class SignupViewSnapshotTests: XCTestCase {
    func testSignupView_default() throws {
        let viewModel = SignupViewModel(authRepository: StubAuthRepository())

        try assertAuthSnapshot(
            SignupView(viewModel: viewModel),
            named: "testSignupView_default"
        )
    }

    func testSignupView_petSectionExpanded() throws {
        let viewModel = makeFilledViewModel()
        viewModel.isPetSectionExpanded = true

        try assertAuthSnapshot(
            SignupView(viewModel: viewModel),
            named: "testSignupView_petSectionExpanded"
        )
    }

    func testSignupView_error() throws {
        let viewModel = makeFilledViewModel()
        viewModel.errorMessage = "Email already taken."

        try assertAuthSnapshot(
            SignupView(viewModel: viewModel),
            named: "testSignupView_error"
        )
    }

    private func makeFilledViewModel() -> SignupViewModel {
        SignupViewModel(
            email: "owner@kilat.my",
            password: "password123",
            fullName: "Mei Ling Chen",
            phone: "+60123456789",
            selectedPetType: .cat,
            petName: "Mochi",
            petWeightKg: "4.2",
            isPetSectionExpanded: true,
            authRepository: StubAuthRepository()
        )
    }
}
