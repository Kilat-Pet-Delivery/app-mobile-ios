import Foundation

enum PetType: String, Codable, CaseIterable, Equatable, Sendable {
    case cat
    case dog
    case bird
    case rabbit
    case reptile
    case other
}

struct PetSpecDTO: Codable, Equatable, Sendable {
    let petType: PetType
    let breed: String
    let name: String
    let weightKg: Double
    let ageMonths: Int
    let vaccinations: [VaccinationDTO]
    let specialNeeds: String
    let photoURL: String

    init(
        petType: PetType,
        breed: String = "",
        name: String,
        weightKg: Double,
        ageMonths: Int = 0,
        vaccinations: [VaccinationDTO] = [],
        specialNeeds: String = "",
        photoURL: String = ""
    ) {
        self.petType = petType
        self.breed = breed
        self.name = name
        self.weightKg = weightKg
        self.ageMonths = ageMonths
        self.vaccinations = vaccinations
        self.specialNeeds = specialNeeds
        self.photoURL = photoURL
    }

    enum CodingKeys: String, CodingKey {
        case petType = "pet_type"
        case breed
        case name
        case weightKg = "weight_kg"
        case ageMonths = "age_months"
        case vaccinations
        case specialNeeds = "special_needs"
        case photoURL = "photo_url"
    }
}

struct VaccinationDTO: Codable, Equatable, Sendable {
    let vaccineName: String
    let dateGiven: Date
    let expiresAt: Date?
    let vetName: String
    let verified: Bool

    enum CodingKeys: String, CodingKey {
        case vaccineName = "vaccine_name"
        case dateGiven = "date_given"
        case expiresAt = "expires_at"
        case vetName = "vet_name"
        case verified
    }
}
