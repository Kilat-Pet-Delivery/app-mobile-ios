import SwiftUI
import XCTest
@testable import KilatOwner

@MainActor
final class HomeViewSnapshotTests: XCTestCase {
    func testHomeView_empty() throws {
        try assertAuthSnapshot(
            HomeView(viewModel: HomeViewModel(homeRepository: HomeSnapshotRepository(snapshot: .homeEmpty), initialSnapshot: .homeEmpty)),
            named: "testHomeView_empty"
        )
    }

    func testHomeView_withBooking() throws {
        let snapshot = HomeSnapshot(
            activeBooking: SampleData.activeBooking,
            pets: [],
            recentTrips: [],
            unreadNotificationCount: 1
        )

        try assertAuthSnapshot(
            HomeView(viewModel: HomeViewModel(homeRepository: HomeSnapshotRepository(snapshot: snapshot), initialSnapshot: snapshot)),
            named: "testHomeView_withBooking"
        )
    }

    func testHomeView_withPetsOnly() throws {
        let snapshot = HomeSnapshot(
            activeBooking: nil,
            pets: [SampleData.mochiPet, SampleData.baoPet],
            recentTrips: [],
            unreadNotificationCount: 0
        )

        try assertAuthSnapshot(
            HomeView(viewModel: HomeViewModel(homeRepository: HomeSnapshotRepository(snapshot: snapshot), initialSnapshot: snapshot)),
            named: "testHomeView_withPetsOnly"
        )
    }

    func testHomeView_full() throws {
        try assertAuthSnapshot(
            HomeView(viewModel: HomeViewModel(homeRepository: HomeSnapshotRepository(snapshot: SampleData.homeSnapshot), initialSnapshot: SampleData.homeSnapshot)),
            named: "testHomeView_full",
            size: CGSize(width: 393, height: 1_320)
        )
    }
}

private struct HomeSnapshotRepository: HomeRepository {
    let snapshot: HomeSnapshot

    func snapshot() async throws -> HomeSnapshot {
        snapshot
    }
}

private extension HomeSnapshot {
    static let homeEmpty = HomeSnapshot(
        activeBooking: nil,
        pets: [],
        recentTrips: [],
        unreadNotificationCount: 0
    )
}
