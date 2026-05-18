import Foundation

struct RunnerPersona: Equatable, Sendable {
    let id: String
    let fullName: String
    let vehicleDescription: String
    let rating: Double
}

enum Personas {
    static let ownerName = "Mei Ling Chen"
    static let ownerEmail = "mei.ling@example.com"
    static let ownerAddressLine = "12 Jalan Ampang"

    static let mochiName = "Mochi"
    static let baoName = "Bao"

    static let aiman = RunnerPersona(
        id: "00000000-0000-0000-0000-000000000002",
        fullName: "Aiman Rahman",
        vehicleDescription: "Motorbike",
        rating: 4.8
    )
}
