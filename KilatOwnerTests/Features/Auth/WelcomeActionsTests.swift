import XCTest
@testable import KilatOwner

@MainActor
final class WelcomeActionsTests: XCTestCase {
    func testBookFirstRun_popToRootThenRoutesHomeAndServices() {
        let coordinator = RootCoordinator(path: [.signup, .welcome])

        WelcomeActions.bookFirstRun(coordinator: coordinator)

        XCTAssertEqual(coordinator.path, [.home, .services(prefilledPetID: nil)])
    }
}
