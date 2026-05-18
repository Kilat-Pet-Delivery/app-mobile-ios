import XCTest
@testable import KilatOwner

@MainActor
final class ServicesViewModelTests: XCTestCase {
    func testServicesVM_initialState_pickerSelectsPrefillIfProvided_orFirstPet() async {
        let prefilled = ServicesViewModel(
            petRepository: ServicesPetRepositoryDouble(pets: [SampleData.mochiPet, SampleData.baoPet]),
            prefilledPetID: SampleData.baoID.uuidString
        )
        await prefilled.load()

        let defaulted = ServicesViewModel(
            petRepository: ServicesPetRepositoryDouble(pets: [SampleData.mochiPet, SampleData.baoPet])
        )
        await defaulted.load()

        XCTAssertEqual(prefilled.selectedPetID, SampleData.baoID.uuidString)
        XCTAssertEqual(defaulted.selectedPetID, SampleData.mochiID.uuidString)
    }

    func testServicesVM_servicetileTap_withoutPet_blocksAndPromptsToChoose() {
        let coordinator = RootCoordinator()
        let viewModel = ServicesViewModel(
            petRepository: ServicesPetRepositoryDouble(pets: []),
            coordinator: coordinator,
            initialPets: []
        )

        viewModel.serviceTileTapped(ServiceCatalog.all[0])

        XCTAssertEqual(viewModel.promptMessage, "Choose a pet before selecting a service.")
        XCTAssertNil(viewModel.lastBookingDraft)
        XCTAssertTrue(coordinator.path.isEmpty)
    }

    func testServicesVM_servicetileTap_withPet_buildsPayloadAndRoutes() {
        let coordinator = RootCoordinator()
        let viewModel = ServicesViewModel(
            petRepository: ServicesPetRepositoryDouble(pets: []),
            coordinator: coordinator,
            initialPets: [SampleData.mochiPet]
        )
        let service = ServiceCatalog.all[0]

        viewModel.serviceTileTapped(service)

        let expectedDraft = ServiceBookingDraft(petID: SampleData.mochiID, serviceID: service.id)
        XCTAssertEqual(viewModel.lastBookingDraft, expectedDraft)
        XCTAssertEqual(coordinator.path, [.bookingDetail(bookingID: expectedDraft.routeBookingID)])
        XCTAssertNil(viewModel.promptMessage)
    }

    func testServicesVM_petListEmpty_showsAddPetCTA() async {
        let viewModel = ServicesViewModel(petRepository: ServicesPetRepositoryDouble(pets: []))

        await viewModel.load()

        XCTAssertTrue(viewModel.showsAddPetCTA)
        XCTAssertNil(viewModel.selectedPet)
        XCTAssertTrue(viewModel.pets.isEmpty)
    }
}

private struct ServicesPetRepositoryDouble: PetRepository {
    let pets: [PetDTO]

    func listMyPets() async throws -> [PetDTO] {
        pets
    }

    func createPet(_ request: CreatePetRequest) async throws -> PetDTO {
        fatalError("Not used in ServicesViewModelTests")
    }
}
