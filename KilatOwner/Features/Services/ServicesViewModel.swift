import Foundation
import Observation

struct ServiceBookingDraft: Equatable, Sendable {
    let petID: UUID
    let serviceID: String

    var routeBookingID: String {
        "draft-\(serviceID)-\(petID.uuidString)"
    }
}

@MainActor
@Observable
final class ServicesViewModel {
    var pets: [PetDTO]
    var selectedPetID: String?
    var isLoading: Bool
    var promptMessage: String?
    var errorMessage: String?
    var lastBookingDraft: ServiceBookingDraft?

    let services: [Service]

    private let petRepository: PetRepository
    private let coordinator: RootCoordinator?
    private let prefilledPetID: String?
    private var hasLoaded: Bool

    init(
        petRepository: PetRepository,
        coordinator: RootCoordinator? = nil,
        prefilledPetID: String? = nil,
        initialPets: [PetDTO]? = nil,
        services: [Service] = ServiceCatalog.all
    ) {
        self.petRepository = petRepository
        self.coordinator = coordinator
        self.prefilledPetID = prefilledPetID
        self.services = services
        self.pets = []
        self.selectedPetID = nil
        self.isLoading = false
        self.hasLoaded = false

        if let initialPets {
            applyPets(initialPets)
            hasLoaded = true
        }
    }

    var selectedPet: PetDTO? {
        pets.first { $0.id.uuidString == selectedPetID }
    }

    var showsAddPetCTA: Bool {
        pets.isEmpty && !isLoading
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    func load() async {
        isLoading = true
        promptMessage = nil
        errorMessage = nil
        defer {
            isLoading = false
            hasLoaded = true
        }

        do {
            applyPets(try await petRepository.listMyPets())
        } catch {
            errorMessage = userMessage(for: error)
        }
    }

    func selectPet(_ pet: PetDTO) {
        selectedPetID = pet.id.uuidString
        promptMessage = nil
    }

    func serviceTileTapped(_ service: Service) {
        guard let selectedPet else {
            promptMessage = "Choose a pet before selecting a service."
            return
        }

        let draft = ServiceBookingDraft(petID: selectedPet.id, serviceID: service.id)
        lastBookingDraft = draft
        promptMessage = nil
        coordinator?.push(.bookingDetail(bookingID: draft.routeBookingID))
    }

    func addPetTapped() {
        promptMessage = "Pet profiles are coming next."
    }

    private func applyPets(_ pets: [PetDTO]) {
        self.pets = pets

        if
            let prefilledPetID,
            pets.contains(where: { $0.id.uuidString == prefilledPetID })
        {
            selectedPetID = prefilledPetID
            return
        }

        selectedPetID = pets.first?.id.uuidString
    }

    private func userMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.userMessage
        }

        if error is URLError {
            return "Unable to load pets. Check your connection and try again."
        }

        return "Unable to load pets. Please try again."
    }
}
