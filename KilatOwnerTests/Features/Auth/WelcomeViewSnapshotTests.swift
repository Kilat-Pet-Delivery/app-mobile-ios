import SwiftUI
import XCTest
@testable import KilatOwner

@MainActor
final class WelcomeViewSnapshotTests: XCTestCase {
    func testWelcomeView_default() throws {
        try assertAuthSnapshot(
            WelcomeView(coordinator: RootCoordinator()),
            named: "testWelcomeView_default"
        )
    }
}
