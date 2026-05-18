import SwiftUI
import XCTest
@testable import KilatOwner

@MainActor
final class PushNotificationsViewSnapshotTests: XCTestCase {
    func testPushNotificationsView_default_dark() throws {
        try assertAuthSnapshot(
            PushNotificationsView(),
            named: "testPushNotificationsView_default_dark",
            size: CGSize(width: 393, height: 852)
        )
    }
}
