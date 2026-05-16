import Foundation
import Observation

@Observable
final class BookingCreateViewModel {
    let shopId: String
    var petName = ""
    var petType = "Dog"
    var petWeightKg = ""
    var dropoffAddress = ""
    var scheduledAt = Date().addingTimeInterval(3600)
    var notes = ""
    private(set) var isSubmitting = false
    var fieldErrors: [String: String] = [:]
    var errorMessage: String?
    var createdBookingId: String?

    let petTypes = ["Dog", "Cat", "Bird", "Rabbit", "Other"]

    @ObservationIgnored private let repository: BookingRepositoryProtocol
    @ObservationIgnored private let appSession: AppSession

    init(
        shopId: String,
        appSession: AppSession,
        repository: BookingRepositoryProtocol = BookingRepository()
    ) {
        self.shopId = shopId
        self.appSession = appSession
        self.repository = repository
    }

    func validate() {
        var errors: [String: String] = [:]
        if petName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors["petName"] = "Pet name is required."
        }
        if Double(petWeightKg) == nil || (Double(petWeightKg) ?? 0) <= 0 {
            errors["petWeightKg"] = "Enter a valid weight."
        }
        if dropoffAddress.trimmingCharacters(in: .whitespacesAndNewlines).count < 10 {
            errors["dropoffAddress"] = "Enter a complete dropoff address."
        }
        if scheduledAt <= Date() {
            errors["scheduledAt"] = "Choose a future time."
        }
        fieldErrors = errors
    }

    @MainActor
    func submit() async {
        errorMessage = nil
        validate()
        guard fieldErrors.isEmpty, let weight = Double(petWeightKg) else {
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let booking = try await repository.create(
                request: CreateBookingRequest(
                    petSpec: PetInfo(
                        petType: petType.lowercased(),
                        breed: "",
                        name: petName,
                        weightKg: weight,
                        specialNeeds: notes,
                        photoURL: ""
                    ),
                    pickupAddress: CreateBookingAddress.placeholder(label: "Pet shop \(shopId)"),
                    dropoffAddress: CreateBookingAddress.placeholder(label: dropoffAddress),
                    scheduledAt: scheduledAt,
                    notes: notes.isEmpty ? nil : notes
                )
            )
            createdBookingId = booking.id
            appSession.activeBookingId = booking.id
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }
}

private extension CreateBookingAddress {
    static func placeholder(label: String) -> CreateBookingAddress {
        CreateBookingAddress(
            line1: label,
            line2: "",
            city: "Kuala Lumpur",
            state: "Kuala Lumpur",
            postalCode: "50000",
            country: "MY",
            latitude: 3.139,
            longitude: 101.6869
        )
    }
}
