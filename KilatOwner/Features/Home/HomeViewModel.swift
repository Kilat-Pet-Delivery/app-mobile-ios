import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    var activeBooking: BookingDTO?
    var pets: [PetDTO]
    var recentTrips: [BookingDTO]
    var unreadNotificationCount: Int
    var isLoading: Bool
    var errorMessage: String?

    let services: [Service]

    private let homeRepository: HomeRepository
    private let coordinator: RootCoordinator?
    private var hasLoaded: Bool

    init(
        homeRepository: HomeRepository,
        coordinator: RootCoordinator? = nil,
        initialSnapshot: HomeSnapshot? = nil,
        services: [Service] = ServiceCatalog.all
    ) {
        self.homeRepository = homeRepository
        self.coordinator = coordinator
        self.services = services
        self.activeBooking = nil
        self.pets = []
        self.recentTrips = []
        self.unreadNotificationCount = 0
        self.isLoading = false
        self.hasLoaded = false

        if let initialSnapshot {
            apply(initialSnapshot)
            hasLoaded = true
        }
    }

    var showsFirstRunCTA: Bool {
        activeBooking == nil && pets.isEmpty && recentTrips.isEmpty
    }

    var showsAddPetCTA: Bool {
        pets.isEmpty
    }

    var hasPets: Bool {
        !pets.isEmpty
    }

    var canTrackActiveBooking: Bool {
        guard let activeBooking else { return false }
        return !activeBooking.status.isTerminal
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
            hasLoaded = true
        }

        do {
            let snapshot = try await homeRepository.snapshot()
            apply(snapshot)
        } catch {
            errorMessage = userMessage(for: error)
        }
    }

    func bookFirstRunTapped() {
        coordinator?.push(.services(prefilledPetID: prefilledPetIDForServiceRoute()))
    }

    func addPetTapped() {
        coordinator?.push(.services(prefilledPetID: nil))
    }

    func serviceTileTapped(_ service: Service) {
        coordinator?.push(.services(prefilledPetID: prefilledPetIDForServiceRoute()))
    }

    func trackActiveBookingTapped() {
        guard let activeBooking, canTrackActiveBooking else { return }
        coordinator?.push(.tracking(bookingID: activeBooking.id.uuidString))
    }

    private func apply(_ snapshot: HomeSnapshot) {
        activeBooking = snapshot.activeBooking
        pets = snapshot.pets
        recentTrips = snapshot.recentTrips.sorted { lhs, rhs in
            lhs.homeSortDate > rhs.homeSortDate
        }
        unreadNotificationCount = snapshot.unreadNotificationCount
    }

    private func prefilledPetIDForServiceRoute() -> String? {
        pets.count == 1 ? pets[0].id.uuidString : nil
    }

    private func userMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.userMessage
        }

        if error is URLError {
            return "Unable to load your home feed. Check your connection and try again."
        }

        return "Unable to load your home feed. Please try again."
    }
}

private extension BookingDTO {
    var homeSortDate: Date {
        deliveredAt ?? pickedUpAt ?? scheduledAt ?? updatedAt
    }
}
