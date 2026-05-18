import Foundation

struct Service: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let iconSFSymbol: String
    let leadTimeHint: String
    let description: String
}

enum ServiceCatalog {
    static let all: [Service] = [
        Service(
            id: "vet",
            name: "Vet visit",
            iconSFSymbol: "cross.case.fill",
            leadTimeHint: "Same day",
            description: "Take your pet to vet appointments"
        ),
        Service(
            id: "grooming",
            name: "Grooming",
            iconSFSymbol: "scissors",
            leadTimeHint: "Within 2 hours",
            description: "Pick up & drop off at grooming salons"
        ),
        Service(
            id: "supplies",
            name: "Supplies run",
            iconSFSymbol: "cart.fill",
            leadTimeHint: "Within 1 hour",
            description: "Fetch food, litter, treats from pet shops"
        ),
        Service(
            id: "boarding",
            name: "Boarding",
            iconSFSymbol: "house.fill",
            leadTimeHint: "Schedule ahead",
            description: "Drop off / pick up from boarding facilities"
        ),
        Service(
            id: "daycare",
            name: "Daycare",
            iconSFSymbol: "sun.max.fill",
            leadTimeHint: "Schedule ahead",
            description: "Drop off & pick up from pet daycare"
        ),
        Service(
            id: "emergency",
            name: "Emergency",
            iconSFSymbol: "cross.fill",
            leadTimeHint: "ASAP",
            description: "Urgent rides for sick or injured pets"
        )
    ]
}
