import CoreLocation
import Foundation
import Observation

// Inline (here, not its own Core/Geocoding/ file) because adding new files needs
// an Xcode UI step to update the .pbxproj. Move into Core/Geocoding/ in the Xcode
// cleanup pass.
protocol AddressGeocoderProtocol {
    func geocode(_ text: String) async throws -> CreateBookingAddress
}

enum AddressGeocoderError: Error, Equatable {
    case notFound
    case transport
}

final class CLAddressGeocoder: AddressGeocoderProtocol {
    private let geocoder = CLGeocoder()

    func geocode(_ text: String) async throws -> CreateBookingAddress {
        let placemarks: [CLPlacemark]
        do {
            placemarks = try await geocoder.geocodeAddressString(text)
        } catch let error as CLError where error.code == .geocodeFoundNoResult {
            throw AddressGeocoderError.notFound
        } catch {
            throw AddressGeocoderError.transport
        }

        guard let first = placemarks.first, let coord = first.location?.coordinate else {
            throw AddressGeocoderError.notFound
        }

        return CreateBookingAddress(
            line1: [first.subThoroughfare, first.thoroughfare]
                .compactMap { $0 }
                .joined(separator: " "),
            line2: first.subLocality ?? "",
            city: first.locality ?? "",
            state: first.administrativeArea ?? "",
            postalCode: first.postalCode ?? "",
            country: first.isoCountryCode ?? first.country ?? "",
            latitude: coord.latitude,
            longitude: coord.longitude
        )
    }
}

enum PickupVerifyState: Equatable {
    case idle
    case verifying
    case verified
    case failed(String)
}

@Observable
final class BookingCreateViewModel {
    // Pre-filled from PetShop detail — locked, displayed read-only.
    let dropoffPrefill: CreateBookingAddress
    let dropoffLabel: String

    // Pet section (matches lib-proto/dto.PetSpecDTO — only pet_type, name, weight_kg
    // are required server-side).
    var petType: String = "dog"
    var petName: String = ""
    var petWeightKgText: String = ""
    var breed: String = ""
    var specialNeeds: String = ""

    // Pickup section — user types free text, CLGeocoder resolves to structured Address.
    var pickupAddressText: String = ""
    private(set) var resolvedPickup: CreateBookingAddress?
    private(set) var pickupVerifyState: PickupVerifyState = .idle

    // Scheduling + notes
    var hasSchedule: Bool = false
    var scheduledAt: Date = Date().addingTimeInterval(3600)
    var notes: String = ""

    // Form state
    private(set) var isSubmitting = false
    var fieldErrors: [String: String] = [:]
    var errorMessage: String?
    var createdBookingId: String?

    // Backend supports these (service-booking pet_specification.go).
    static let petTypes = ["cat", "dog", "bird", "rabbit", "reptile", "other"]

    @ObservationIgnored private let repository: BookingRepositoryProtocol
    @ObservationIgnored private let appSession: AppSession
    @ObservationIgnored private let geocoder: AddressGeocoderProtocol

    init(
        dropoffPrefill: CreateBookingAddress,
        dropoffLabel: String,
        appSession: AppSession,
        repository: BookingRepositoryProtocol = BookingRepository(),
        geocoder: AddressGeocoderProtocol = CLAddressGeocoder()
    ) {
        self.dropoffPrefill = dropoffPrefill
        self.dropoffLabel = dropoffLabel
        self.appSession = appSession
        self.repository = repository
        self.geocoder = geocoder
    }

    @MainActor
    func verifyPickup() async {
        let trimmed = pickupAddressText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            pickupVerifyState = .failed("Type a pickup address first.")
            return
        }

        pickupVerifyState = .verifying
        do {
            let resolved = try await geocoder.geocode(trimmed)
            resolvedPickup = resolved
            pickupVerifyState = .verified
        } catch AddressGeocoderError.notFound {
            resolvedPickup = nil
            pickupVerifyState = .failed("Couldn't find that address — try a more specific one.")
        } catch {
            resolvedPickup = nil
            pickupVerifyState = .failed("Network error — try again in a moment.")
        }
    }

    func validate() {
        var errors: [String: String] = [:]
        if petName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors["petName"] = "Pet name is required."
        }
        if !Self.petTypes.contains(petType) {
            errors["petType"] = "Pick a pet type."
        }
        let weight = Double(petWeightKgText) ?? 0
        if weight <= 0 {
            errors["petWeightKg"] = "Enter a valid weight."
        }
        if resolvedPickup == nil {
            errors["pickupAddress"] = "Tap Verify to confirm the pickup address."
        }
        if hasSchedule, scheduledAt <= Date() {
            errors["scheduledAt"] = "Choose a future time."
        }
        fieldErrors = errors
    }

    @MainActor
    func submit() async {
        errorMessage = nil
        validate()
        guard fieldErrors.isEmpty,
              let weight = Double(petWeightKgText),
              let pickup = resolvedPickup else {
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let booking = try await repository.create(
                request: CreateBookingRequest(
                    petSpec: PetInfo(
                        petType: petType,
                        breed: breed,
                        name: petName,
                        weightKg: weight,
                        specialNeeds: specialNeeds,
                        photoURL: ""
                    ),
                    pickupAddress: pickup,
                    dropoffAddress: dropoffPrefill,
                    scheduledAt: hasSchedule ? scheduledAt : nil,
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
