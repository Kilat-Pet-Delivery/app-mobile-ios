import Foundation

struct AddressDTO: Codable, Equatable, Sendable {
    let line1: String
    let line2: String
    let city: String
    let state: String
    let postalCode: String
    let country: String
    let latitude: Double
    let longitude: Double

    enum CodingKeys: String, CodingKey {
        case line1
        case line2
        case city
        case state
        case postalCode = "postal_code"
        case country
        case latitude
        case longitude
    }
}
