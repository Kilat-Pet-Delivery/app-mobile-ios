import Foundation

struct LoginRequest: Codable, Equatable, Sendable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable, Equatable, Sendable {
    let email: String
    let phone: String
    let fullName: String
    let password: String
    let role: String
    let firstPet: RegisterPetRequest?

    init(
        email: String,
        phone: String,
        fullName: String,
        password: String,
        role: String = "owner",
        firstPet: RegisterPetRequest? = nil
    ) {
        self.email = email
        self.phone = phone
        self.fullName = fullName
        self.password = password
        self.role = role
        self.firstPet = firstPet
    }

    enum CodingKeys: String, CodingKey {
        case email
        case phone
        case fullName = "full_name"
        case password
        case role
        case firstPet = "first_pet"
    }
}

struct RegisterPetRequest: Codable, Equatable, Sendable {
    let petType: PetType
    let name: String
    let weightKg: Double

    enum CodingKeys: String, CodingKey {
        case petType = "pet_type"
        case name
        case weightKg = "weight_kg"
    }
}

struct LoginResponse: Codable, Equatable, Sendable {
    let accessToken: String
    let refreshToken: String
    let user: ProfileDTO

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

struct ProfileDTO: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let email: String
    let phone: String
    let fullName: String
    let role: String
    let isVerified: Bool
    let avatarURL: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case phone
        case fullName = "full_name"
        case role
        case isVerified = "is_verified"
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
    }
}

struct ForgotPasswordRequest: Codable, Equatable, Sendable {
    let email: String
}

struct ResetPasswordRequest: Codable, Equatable, Sendable {
    let token: String
    let newPassword: String

    enum CodingKeys: String, CodingKey {
        case token
        case newPassword
    }
}
