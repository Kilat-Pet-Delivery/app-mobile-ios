import Foundation
import Observation

@Observable
final class RegisterViewModel {
    var email = ""
    var password = ""
    var firstName = ""
    var lastName = ""
    var phone = ""
    private(set) var isLoading = false
    var errorMessage: String?
    var fieldErrors: [String: String] = [:]

    var canSubmit: Bool {
        fieldErrors.isEmpty
            && !email.isEmpty
            && !password.isEmpty
            && !firstName.isEmpty
            && !lastName.isEmpty
            && !phone.isEmpty
            && !isLoading
    }

    @ObservationIgnored private let authRepository: AuthRepositoryProtocol
    @ObservationIgnored private let appSession: AppSession

    init(authRepository: AuthRepositoryProtocol, appSession: AppSession) {
        self.authRepository = authRepository
        self.appSession = appSession
    }

    convenience init(appSession: AppSession) {
        self.init(authRepository: AuthRepository(), appSession: appSession)
    }

    func validate() {
        var errors: [String: String] = [:]

        if !email.contains("@") || !email.contains(".") {
            errors["email"] = "Enter a valid email."
        }
        if password.count < 8 {
            errors["password"] = "Use at least 8 characters."
        }
        if firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors["firstName"] = "First name is required."
        }
        if lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors["lastName"] = "Last name is required."
        }

        let digits = phone.filter(\.isNumber)
        if digits.count < 10 || digits != phone {
            errors["phone"] = "Use digits only, at least 10 numbers."
        }

        fieldErrors = errors
    }

    @MainActor
    func register() async {
        errorMessage = nil
        validate()

        guard fieldErrors.isEmpty else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await authRepository.register(
                RegisterRequest(
                    email: email,
                    password: password,
                    firstName: firstName,
                    lastName: lastName,
                    phone: phone
                )
            )
            appSession.markAuthenticated(user: user)
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }
}
