import SwiftUI
import XCTest
@testable import KilatOwner

@MainActor
final class ResetSentViewSnapshotTests: XCTestCase {
    func testResetSentView_default() throws {
        try assertAuthSnapshot(
            ResetSentView(coordinator: RootCoordinator(), openMail: { _ in }),
            named: "testResetSentView_default"
        )
    }
}
