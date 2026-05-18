import Foundation

struct CreateBookingRequest: Codable, Equatable, Sendable {
    let petSpec: PetSpecDTO
    let pickupAddress: AddressDTO
    let dropoffAddress: AddressDTO
    let scheduledAt: Date?
    let notes: String

    init(
        petSpec: PetSpecDTO,
        pickupAddress: AddressDTO,
        dropoffAddress: AddressDTO,
        scheduledAt: Date? = nil,
        notes: String = ""
    ) {
        self.petSpec = petSpec
        self.pickupAddress = pickupAddress
        self.dropoffAddress = dropoffAddress
        self.scheduledAt = scheduledAt
        self.notes = notes
    }

    enum CodingKeys: String, CodingKey {
        case petSpec = "pet_spec"
        case pickupAddress = "pickup_address"
        case dropoffAddress = "dropoff_address"
        case scheduledAt = "scheduled_at"
        case notes
    }
}

struct BookingDTO: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let bookingNumber: String
    let ownerID: UUID
    let runnerID: UUID?
    let status: BookingStatus
    let petSpec: PetSpecDTO
    let crateRequirement: CrateRequirementDTO
    let pickupAddress: AddressDTO
    let dropoffAddress: AddressDTO
    let routeSpec: RouteSpecDTO?
    let estimatedPriceCents: Int64
    let finalPriceCents: Int64?
    let currency: String
    let scheduledAt: Date?
    let pickedUpAt: Date?
    let deliveredAt: Date?
    let cancelledAt: Date?
    let cancelNote: String
    let notes: String
    let version: Int64
    let createdAt: Date
    let updatedAt: Date

    var amountCents: Int64 {
        finalPriceCents ?? estimatedPriceCents
    }

    enum CodingKeys: String, CodingKey {
        case id
        case bookingNumber = "booking_number"
        case ownerID = "owner_id"
        case runnerID = "runner_id"
        case status
        case petSpec = "pet_spec"
        case crateRequirement = "crate_requirement"
        case pickupAddress = "pickup_address"
        case dropoffAddress = "dropoff_address"
        case routeSpec = "route_spec"
        case estimatedPriceCents = "estimated_price_cents"
        case finalPriceCents = "final_price_cents"
        case currency
        case scheduledAt = "scheduled_at"
        case pickedUpAt = "picked_up_at"
        case deliveredAt = "delivered_at"
        case cancelledAt = "cancelled_at"
        case cancelNote = "cancel_note"
        case notes
        case version
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct CrateRequirementDTO: Codable, Equatable, Sendable {
    let minimumSize: String
    let needsVentilation: Bool
    let needsTempControl: Bool
    let minimumWeightCapacity: Double

    enum CodingKeys: String, CodingKey {
        case minimumSize = "minimum_size"
        case needsVentilation = "needs_ventilation"
        case needsTempControl = "needs_temp_control"
        case minimumWeightCapacity = "minimum_weight_capacity"
    }
}

struct RouteSpecDTO: Codable, Equatable, Sendable {
    let pickupLat: Double
    let pickupLng: Double
    let dropoffLat: Double
    let dropoffLng: Double
    let distanceKm: Double
    let estimatedDurationMin: Int
    let polyline: String

    enum CodingKeys: String, CodingKey {
        case pickupLat = "pickup_lat"
        case pickupLng = "pickup_lng"
        case dropoffLat = "dropoff_lat"
        case dropoffLng = "dropoff_lng"
        case distanceKm = "distance_km"
        case estimatedDurationMin = "estimated_duration_min"
        case polyline
    }
}

struct CancelBookingRequest: Codable, Equatable, Sendable {
    let reason: CancelReason
}
