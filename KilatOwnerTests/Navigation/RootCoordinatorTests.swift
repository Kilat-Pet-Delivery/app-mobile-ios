import XCTest
@testable import KilatOwner

@MainActor
final class RootCoordinatorTests: XCTestCase {
    func testPush_addsRouteToPath() {
        let coordinator = RootCoordinator()

        coordinator.push(.bookingDetail(bookingID: "booking-1"))

        XCTAssertEqual(coordinator.path, [.bookingDetail(bookingID: "booking-1")])
    }

    func testSetRoot_replacesRootRouteAndClearsPath() {
        let coordinator = RootCoordinator(rootRoute: .login, path: [.signup, .welcome])

        coordinator.setRoot(.home)

        XCTAssertEqual(coordinator.rootRoute, .home)
        XCTAssertTrue(coordinator.path.isEmpty)
    }

    func testPop_removesLastRoute() {
        let coordinator = RootCoordinator()
        coordinator.push(.home)
        coordinator.push(.notifications)

        coordinator.pop()

        XCTAssertEqual(coordinator.path, [.home])
    }

    func testPopToRoot_clearsPath() {
        let coordinator = RootCoordinator()
        coordinator.push(.services(prefilledPetID: "pet-1"))
        coordinator.push(.bookingDetail(bookingID: "booking-1"))

        coordinator.popToRoot()

        XCTAssertTrue(coordinator.path.isEmpty)
    }
}
