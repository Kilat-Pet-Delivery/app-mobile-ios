import XCTest
@testable import KilatOwner

@MainActor
final class SignupViewModelTests: XCTestCase {
    func testSignupVM_allFieldsValid_callsRegisterAndRoutesToWelcome() async {
        let repository = SignupAuthRepository()
        let coordinator = RootCoordinator()
        let viewModel = makeViewModel(repository: repository, coordinator: coordinator)

        await viewModel.submit()

        XCTAssertEqual(repository.registerRequests.count, 1)
        XCTAssertEqual(repository.registerRequests.first?.email, "owner@kilat.my")
        XCTAssertEqual(repository.registerRequests.first?.fullName, "Mei Ling Chen")
        XCTAssertEqual(repository.registerRequests.first?.phone, "+60123456789")
        XCTAssertEqual(repository.registerRequests.first?.role, "owner")
        XCTAssertEqual(repository.registerRequests.first?.firstPet, RegisterPetRequest(petType: .cat, name: "Mochi", weightKg: 4.2))
        XCTAssertEqual(coordinator.path, [.welcome])
        XCTAssertEqual(viewModel.authenticatedProfile, SampleData.ownerProfile)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testSignupVM_passwordTooShort_blocksSubmit_withValidationError() async {
        let repository = SignupAuthRepository()
        let viewModel = makeViewModel(password: "short", repository: repository)

        await viewModel.submit()

        XCTAssertEqual(viewModel.validationError, "Password must be at least 8 characters.")
        XCTAssertTrue(repository.registerRequests.isEmpty)
    }

    func testSignupVM_invalidPhone_blocksSubmit_withValidationError() async {
        let repository = SignupAuthRepository()
        let viewModel = makeViewModel(phone: "555-0100", repository: repository)

        await viewModel.submit()

        XCTAssertEqual(viewModel.validationError, "Enter a Malaysian phone number that starts with +60 or 01.")
        XCTAssertTrue(repository.registerRequests.isEmpty)
    }

    func testSignupVM_emailTaken_surfacesServerErrorMessage() async {
        let repository = SignupAuthRepository(error: APIError.serverFailure(message: "Email already taken."))
        let viewModel = makeViewModel(repository: repository)

        await viewModel.submit()

        XCTAssertEqual(viewModel.errorMessage, "Email already taken.")
        XCTAssertNil(viewModel.validationError)
        XCTAssertEqual(repository.registerRequests.count, 1)
    }

    func testSignupVM_petWeightZero_blocksSubmit_withValidationError() async {
        let repository = SignupAuthRepository()
        let viewModel = makeViewModel(petWeightKg: "0", repository: repository)

        await viewModel.submit()

        XCTAssertEqual(viewModel.validationError, "Enter a pet weight greater than 0 kg.")
        XCTAssertTrue(viewModel.isPetSectionExpanded)
        XCTAssertTrue(repository.registerRequests.isEmpty)
    }

    func testSignupVM_petTypeNotSelected_blocksSubmit_withValidationError() async {
        let repository = SignupAuthRepository()
        let viewModel = makeViewModel(selectedPetType: nil, repository: repository)

        await viewModel.submit()

        XCTAssertEqual(viewModel.validationError, "Select your pet type.")
        XCTAssertTrue(viewModel.isPetSectionExpanded)
        XCTAssertTrue(repository.registerRequests.isEmpty)
    }

    private func makeViewModel(
        email: String = "owner@kilat.my",
        password: String = "password123",
        fullName: String = "Mei Ling Chen",
        phone: String = "+60123456789",
        selectedPetType: PetType? = .cat,
        petName: String = "Mochi",
        petWeightKg: String = "4.2",
        repository: SignupAuthRepository,
        coordinator: RootCoordinator? = nil
    ) -> SignupViewModel {
        SignupViewModel(
            email: email,
            password: password,
            fullName: fullName,
            phone: phone,
            selectedPetType: selectedPetType,
            petName: petName,
            petWeightKg: petWeightKg,
            isPetSectionExpanded: true,
            authRepository: repository,
            coordinator: coordinator
        )
    }
}

private final class SignupAuthRepository: AuthRepository {
    private let error: Error?
    private(set) var registerRequests: [RegisterRequest] = []

    init(error: Error? = nil) {
        self.error = error
    }

    func login(email: String, password: String) async throws -> LoginResponse {
        throw APIError.unauthorized
    }

    func register(_ request: RegisterRequest) async throws -> LoginResponse {
        registerRequests.append(request)

        if let error {
            throw error
        }

        return LoginResponse(
            accessToken: "stub-access-token",
            refreshToken: "stub-refresh-token",
            user: SampleData.ownerProfile
        )
    }

    func forgotPassword(email: String) async throws {}

    func resetPassword(token: String, newPassword: String) async throws {}

    func profile() async throws -> ProfileDTO {
        SampleData.ownerProfile
    }

    func logout() async throws {}
}
