import SwiftUI
import XCTest
@testable import KilatOwner

@MainActor
final class ServicesViewSnapshotTests: XCTestCase {
    func testServicesView_default_petPreselected() throws {
        let pets = [SampleData.mochiPet, SampleData.baoPet]

        try assertAuthSnapshot(
            ServicesView(
                viewModel: ServicesViewModel(
                    petRepository: ServicesSnapshotPetRepository(pets: pets),
                    prefilledPetID: SampleData.mochiID.uuidString,
                    initialPets: pets
                )
            ),
            named: "testServicesView_default_petPreselected",
            size: CGSize(width: 393, height: 1_120)
        )
    }

    func testServicesView_noPetsYet() throws {
        try assertAuthSnapshot(
            ServicesView(
                viewModel: ServicesViewModel(
                    petRepository: ServicesSnapshotPetRepository(pets: []),
                    initialPets: []
                )
            ),
            named: "testServicesView_noPetsYet",
            size: CGSize(width: 393, height: 1_080)
        )
    }
}

private struct ServicesSnapshotPetRepository: PetRepository {
    let pets: [PetDTO]

    func listMyPets() async throws -> [PetDTO] {
        pets
    }

    func createPet(_ request: CreatePetRequest) async throws -> PetDTO {
        fatalError("Not used in ServicesViewSnapshotTests")
    }
}
