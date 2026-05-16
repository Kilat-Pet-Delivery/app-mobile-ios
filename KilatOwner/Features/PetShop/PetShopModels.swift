import Foundation

struct PetShop: Decodable, Equatable, Identifiable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let phone: String
    let email: String?
    let category: String
    let services: [String]
    let rating: Double
    let imageURL: String?
    let openingHours: String?
    let description: String?
    let createdAt: Date?

    var categoryDisplay: String {
        switch category {
        case "grooming": return "Grooming"
        case "vet": return "Veterinary"
        case "boarding": return "Boarding"
        case "pet_store": return "Pet Store"
        default: return category.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    var serviceModels: [PetShopService] {
        services.enumerated().map { index, service in
            PetShopService(
                id: "\(id)-service-\(index)",
                name: service,
                description: nil,
                priceCents: nil
            )
        }
    }
}

struct PetShopService: Decodable, Equatable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let priceCents: Int?
}
