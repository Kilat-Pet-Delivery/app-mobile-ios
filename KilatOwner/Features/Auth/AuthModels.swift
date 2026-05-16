import Foundation

struct LoginRequest: Encodable, Equatable {
    let email: String
    let password: String
}

struct RegisterRequest: Encodable, Equatable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let phone: String
}

struct LoginResponse: Decodable, Equatable {
    let accessToken: String
    let refreshToken: String
    let user: User
}

typealias AuthResponse = LoginResponse
typealias AuthenticatedUser = User

struct User: Decodable, Equatable, Identifiable {
    let id: String
    let email: String
    let phone: String?
    let firstName: String?
    let lastName: String?
    let fullName: String?
    let role: String
    let isVerified: Bool
    let avatarURL: String?
    let createdAt: Date?

    var displayName: String {
        if let fullName, !fullName.isEmpty {
            return fullName
        }

        return [firstName, lastName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    init(
        id: String,
        email: String,
        phone: String?,
        firstName: String? = nil,
        lastName: String? = nil,
        fullName: String? = nil,
        role: String,
        isVerified: Bool,
        avatarURL: String?,
        createdAt: Date?
    ) {
        self.id = id
        self.email = email
        self.phone = phone
        self.firstName = firstName
        self.lastName = lastName
        self.fullName = fullName
        self.role = role
        self.isVerified = isVerified
        self.avatarURL = avatarURL
        self.createdAt = createdAt
    }
}
