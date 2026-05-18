import Foundation
import Observation

@MainActor
@Observable
final class ForgotPasswordViewModel {
    var email: String
    var isLoading: Bool
    var validationError: String?
    var errorMessage: String?

    private let authRepository: AuthRepository
    private let coordinator: RootCoordinator?

    init(
        email: String = "",
        authRepository: AuthRepository,
        coordinator: RootCoordinator? = nil
    ) {
        self.email = email
        self.authRepository = authRepository
        self.coordinator = coordinator
        self.isLoading = false
    }

    func submit() async {
        validationError = nil
        errorMessage = nil

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isValidEmail(trimmedEmail) else {
            validationError = "Enter a valid email address."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await authRepository.forgotPassword(email: trimmedEmail)
            coordinator?.push(.resetSent)
        } catch {
            errorMessage = message(for: error)
        }
    }

    private static func isValidEmail(_ email: String) -> Bool {
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2 else { return false }
        guard let local = parts.first, let domain = parts.last else { return false }
        return !local.isEmpty && domain.contains(".") && !domain.hasSuffix(".")
    }

    private func message(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.userMessage
        }

        if error is URLError {
            return "Unable to send the reset link. Check your connection and try again."
        }

        return "Unable to send the reset link. Please try again."
    }
}
