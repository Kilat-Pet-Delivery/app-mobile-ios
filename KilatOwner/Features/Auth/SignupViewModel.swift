import Foundation
import Observation

@MainActor
@Observable
final class SignupViewModel {
    var email: String
    var password: String
    var fullName: String
    var phone: String
    var selectedPetType: PetType?
    var petName: String
    var petWeightKg: String
    var isPetSectionExpanded: Bool
    var isLoading = false
    var validationError: String?
    var errorMessage: String?
    var authenticatedProfile: ProfileDTO?

    private let authRepository: AuthRepository
    private let coordinator: RootCoordinator?

    init(
        email: String = "",
        password: String = "",
        fullName: String = "",
        phone: String = "",
        selectedPetType: PetType? = nil,
        petName: String = "",
        petWeightKg: String = "",
        isPetSectionExpanded: Bool = false,
        authRepository: AuthRepository,
        coordinator: RootCoordinator? = nil
    ) {
        self.email = email
        self.password = password
        self.fullName = fullName
        self.phone = phone
        self.selectedPetType = selectedPetType
        self.petName = petName
        self.petWeightKg = petWeightKg
        self.isPetSectionExpanded = isPetSectionExpanded
        self.authRepository = authRepository
        self.coordinator = coordinator
    }

    func submit() async {
        validationError = nil
        errorMessage = nil

        guard let request = makeRegisterRequest() else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await authRepository.register(request)
            authenticatedProfile = response.user
            coordinator?.push(.welcome)
        } catch {
            errorMessage = userMessage(for: error)
        }
    }

    func petTypeLabel(_ type: PetType) -> String {
        switch type {
        case .cat:
            return "Cat"
        case .dog:
            return "Dog"
        case .bird:
            return "Bird"
        case .rabbit:
            return "Rabbit"
        case .reptile:
            return "Reptile"
        case .other:
            return "Other"
        }
    }

    private func makeRegisterRequest() -> RegisterRequest? {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPetName = petName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            validationError = "Enter your full name."
            return nil
        }

        guard isValidEmail(trimmedEmail) else {
            validationError = "Enter a valid email address."
            return nil
        }

        guard isValidMalaysianPhone(trimmedPhone) else {
            validationError = "Enter a Malaysian phone number that starts with +60 or 01."
            return nil
        }

        guard password.count >= 8 else {
            validationError = "Password must be at least 8 characters."
            return nil
        }

        guard let selectedPetType else {
            isPetSectionExpanded = true
            validationError = "Select your pet type."
            return nil
        }

        guard !trimmedPetName.isEmpty else {
            isPetSectionExpanded = true
            validationError = "Enter your pet name."
            return nil
        }

        guard let weight = Double(petWeightKg), weight > 0 else {
            isPetSectionExpanded = true
            validationError = "Enter a pet weight greater than 0 kg."
            return nil
        }

        return RegisterRequest(
            email: trimmedEmail,
            phone: trimmedPhone,
            fullName: trimmedName,
            password: password,
            firstPet: RegisterPetRequest(
                petType: selectedPetType,
                name: trimmedPetName,
                weightKg: weight
            )
        )
    }

    private func isValidEmail(_ value: String) -> Bool {
        let parts = value.split(separator: "@")
        guard parts.count == 2, let domain = parts.last else { return false }
        return domain.contains(".") && !String(domain).hasSuffix(".")
    }

    private func isValidMalaysianPhone(_ value: String) -> Bool {
        let digits = value.filter(\.isNumber)

        if value.hasPrefix("+60") {
            return digits.count >= 10 && digits.count <= 12
        }

        if value.hasPrefix("01") {
            return digits.count >= 10 && digits.count <= 11
        }

        return false
    }

    private func userMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.userMessage
        }

        if error is URLError {
            return "Unable to create your account. Check your connection and try again."
        }

        return "Unable to create your account. Please try again."
    }
}
