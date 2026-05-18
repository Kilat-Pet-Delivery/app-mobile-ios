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

struct CreatePetRequest: Codable, Equatable, Sendable {
    let name: String
    let petType: PetType
    let breed: String
    let weightKg: Double
    let ageMonths: Int
    let allergies: String
    let specialNeeds: String
    let notes: String
    let photoURL: String
    let vaccinationStatus: String

    init(
        name: String,
        petType: PetType,
        breed: String = "",
        weightKg: Double,
        ageMonths: Int = 0,
        allergies: String = "",
        specialNeeds: String = "",
        notes: String = "",
        photoURL: String = "",
        vaccinationStatus: String = ""
    ) {
        self.name = name
        self.petType = petType
        self.breed = breed
        self.weightKg = weightKg
        self.ageMonths = ageMonths
        self.allergies = allergies
        self.specialNeeds = specialNeeds
        self.notes = notes
        self.photoURL = photoURL
        self.vaccinationStatus = vaccinationStatus
    }

    enum CodingKeys: String, CodingKey {
        case name
        case petType = "pet_type"
        case breed
        case weightKg = "weight_kg"
        case ageMonths = "age_months"
        case allergies
        case specialNeeds = "special_needs"
        case notes
        case photoURL = "photo_url"
        case vaccinationStatus = "vaccination_status"
    }
}

struct PetDTO: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let ownerID: UUID
    let name: String
    let petType: PetType
    let breed: String
    let weightKg: Double
    let ageMonths: Int
    let allergies: String
    let specialNeeds: String
    let notes: String
    let photoURL: String
    let vaccinationStatus: String
    let status: String
    let createdAt: Date
    let updatedAt: Date

    var spec: PetSpecDTO {
        PetSpecDTO(
            petType: petType,
            breed: breed,
            name: name,
            weightKg: weightKg,
            ageMonths: ageMonths,
            specialNeeds: specialNeeds,
            photoURL: photoURL
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case name
        case petType = "pet_type"
        case breed
        case weightKg = "weight_kg"
        case ageMonths = "age_months"
        case allergies
        case specialNeeds = "special_needs"
        case notes
        case photoURL = "photo_url"
        case vaccinationStatus = "vaccination_status"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
