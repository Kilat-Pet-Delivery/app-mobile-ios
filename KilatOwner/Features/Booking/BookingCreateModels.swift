import Foundation

struct PetInfo: Encodable, Equatable {
    let petType: String
    let breed: String
    let name: String
    let weightKg: Double
    let specialNeeds: String
    let photoURL: String
}

struct CreateBookingAddress: Encodable, Equatable {
    let line1: String
    let line2: String
    let city: String
    let state: String
    let postalCode: String
    let country: String
    let latitude: Double
    let longitude: Double
}

struct CreateBookingRequest: Encodable, Equatable {
    let petSpec: PetInfo
    let pickupAddress: CreateBookingAddress
    let dropoffAddress: CreateBookingAddress
    let scheduledAt: Date?
    let notes: String?
}
