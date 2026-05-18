import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    var email: String
    var password: String
    var isLoading: Bool
    var errorMessage: String?
    var validationError: String?
    var authenticatedProfile: ProfileDTO?

    private let authRepository: AuthRepository
    private let coordinator: RootCoordinator?
    private let onAuthenticated: (LoginResponse) -> Void

    init(
        email: String = "",
        password: String = "",
        authRepository: AuthRepository,
        coordinator: RootCoordinator? = nil,
        onAuthenticated: @escaping (LoginResponse) -> Void = { _ in }
    ) {
        self.email = email
        self.password = password
        self.authRepository = authRepository
        self.coordinator = coordinator
        self.onAuthenticated = onAuthenticated
        self.isLoading = false
    }

    func submit() async {
        errorMessage = nil
        validationError = nil

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            validationError = "Please enter your email."
            return
        }

        guard !password.isEmpty else {
            validationError = "Please enter your password."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await authRepository.login(email: trimmedEmail, password: password)
            authenticatedProfile = response.user
            onAuthenticated(response)
            coordinator?.popToRoot()
            coordinator?.push(.home)
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    func forgotPasswordTapped() {
        coordinator?.push(.forgotPassword)
    }

    private static func message(for error: Error) -> String {
        if let apiError = error as? APIError {
            switch apiError {
            case .network:
                return "Unable to sign in. Check your connection and try again."
            case .serverFailure:
                return apiError.userMessage
            default:
                return apiError.userMessage
            }
        }

        if error is URLError {
            return "Unable to sign in. Check your connection and try again."
        }

        return "We could not sign you in. Please try again."
    }
}
