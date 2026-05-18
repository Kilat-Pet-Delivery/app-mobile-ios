import XCTest
@testable import KilatOwner

final class BookingStatusTests: XCTestCase {
    func testDisplayLabel_mapsBackendEnumToDesignString() {
        XCTAssertEqual(BookingStatus.requested.displayLabel, "Pending")
        XCTAssertEqual(BookingStatus.accepted.displayLabel, "Confirmed")
        XCTAssertEqual(BookingStatus.inProgress.displayLabel, "En route")
        XCTAssertEqual(BookingStatus.delivered.displayLabel, "Delivered")
    }

    func testDisplayLabel_handlesTerminalBackendStates() {
        XCTAssertEqual(BookingStatus.completed.displayLabel, "Completed")
        XCTAssertEqual(BookingStatus.cancelled.displayLabel, "Cancelled")
    }
}
