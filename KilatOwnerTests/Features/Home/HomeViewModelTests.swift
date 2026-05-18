import XCTest
@testable import KilatOwner

@MainActor
final class HomeViewModelTests: XCTestCase {
    func testHomeVM_emptyState_noBookingNoPetsNoTrips_rendersEmptyCTAs() async {
        let viewModel = HomeViewModel(homeRepository: HomeRepositoryDouble(snapshot: .empty))

        await viewModel.load()

        XCTAssertTrue(viewModel.showsFirstRunCTA)
        XCTAssertTrue(viewModel.showsAddPetCTA)
        XCTAssertNil(viewModel.activeBooking)
        XCTAssertTrue(viewModel.pets.isEmpty)
        XCTAssertTrue(viewModel.recentTrips.isEmpty)
    }

    func testHomeVM_withActiveBooking_rendersStatusBadge_andTrackCTA() async {
        let coordinator = RootCoordinator()
        let viewModel = HomeViewModel(
            homeRepository: HomeRepositoryDouble(snapshot: .with(activeBooking: SampleData.activeBooking)),
            coordinator: coordinator
        )

        await viewModel.load()
        viewModel.trackActiveBookingTapped()

        XCTAssertEqual(viewModel.activeBooking?.status.displayLabel, "En route")
        XCTAssertTrue(viewModel.canTrackActiveBooking)
        XCTAssertEqual(coordinator.path, [.tracking(bookingID: SampleData.activeBookingID.uuidString)])
    }

    func testHomeVM_withPetsButNoBooking_rendersPetRow() async {
        let viewModel = HomeViewModel(
            homeRepository: HomeRepositoryDouble(snapshot: .with(pets: [SampleData.mochiPet, SampleData.baoPet]))
        )

        await viewModel.load()

        XCTAssertTrue(viewModel.hasPets)
        XCTAssertFalse(viewModel.showsFirstRunCTA)
        XCTAssertEqual(viewModel.pets.map(\.name), [SampleData.mochiPet.name, SampleData.baoPet.name])
    }

    func testHomeVM_withRecentTrips_rendersTripList_sortedByDateDescending() async {
        let older = Self.trip(number: "KLT-OLD", deliveredAt: SampleData.baseDate.addingTimeInterval(-86_400))
        let newer = Self.trip(number: "KLT-NEW", deliveredAt: SampleData.baseDate.addingTimeInterval(-3_600))
        let viewModel = HomeViewModel(
            homeRepository: HomeRepositoryDouble(snapshot: .with(recentTrips: [older, newer]))
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.recentTrips.map(\.bookingNumber), ["KLT-NEW", "KLT-OLD"])
    }

    func testHomeVM_servicetileTap_pushesServicesRoute_withPrefilledPetID_ifSinglePet() {
        let coordinator = RootCoordinator()
        let viewModel = HomeViewModel(
            homeRepository: HomeRepositoryDouble(snapshot: .empty),
            coordinator: coordinator,
            initialSnapshot: .with(pets: [SampleData.mochiPet])
        )

        viewModel.serviceTileTapped(ServiceCatalog.all[0])

        XCTAssertEqual(coordinator.path, [.services(prefilledPetID: SampleData.mochiID.uuidString)])
    }

    func testHomeVM_servicetileTap_pushesServicesRoute_withNilPet_ifMultiplePets() {
        let coordinator = RootCoordinator()
        let viewModel = HomeViewModel(
            homeRepository: HomeRepositoryDouble(snapshot: .empty),
            coordinator: coordinator,
            initialSnapshot: .with(pets: [SampleData.mochiPet, SampleData.baoPet])
        )

        viewModel.serviceTileTapped(ServiceCatalog.all[0])

        XCTAssertEqual(coordinator.path, [.services(prefilledPetID: nil)])
    }

    private static func trip(number: String, deliveredAt: Date) -> BookingDTO {
        let base = SampleData.completedBooking
        return BookingDTO(
            id: UUID(),
            bookingNumber: number,
            ownerID: base.ownerID,
            runnerID: base.runnerID,
            status: base.status,
            petSpec: base.petSpec,
            crateRequirement: base.crateRequirement,
            pickupAddress: base.pickupAddress,
            dropoffAddress: base.dropoffAddress,
            routeSpec: base.routeSpec,
            estimatedPriceCents: base.estimatedPriceCents,
            finalPriceCents: base.finalPriceCents,
            currency: base.currency,
            scheduledAt: base.scheduledAt,
            pickedUpAt: base.pickedUpAt,
            deliveredAt: deliveredAt,
            cancelledAt: base.cancelledAt,
            cancelNote: base.cancelNote,
            notes: base.notes,
            version: base.version,
            createdAt: deliveredAt.addingTimeInterval(-1_800),
            updatedAt: deliveredAt
        )
    }
}

private struct HomeRepositoryDouble: HomeRepository {
    let snapshot: HomeSnapshot

    func snapshot() async throws -> HomeSnapshot {
        snapshot
    }
}

private extension HomeSnapshot {
    static let empty = HomeSnapshot(
        activeBooking: nil,
        pets: [],
        recentTrips: [],
        unreadNotificationCount: 0
    )

    static func with(
        activeBooking: BookingDTO? = nil,
        pets: [PetDTO] = [],
        recentTrips: [BookingDTO] = [],
        unreadNotificationCount: Int = 0
    ) -> HomeSnapshot {
        HomeSnapshot(
            activeBooking: activeBooking,
            pets: pets,
            recentTrips: recentTrips,
            unreadNotificationCount: unreadNotificationCount
        )
    }
}
