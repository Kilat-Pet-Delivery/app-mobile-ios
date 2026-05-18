import SwiftUI
import XCTest
@testable import KilatOwner

@MainActor
final class CancelReasonSheetSnapshotTests: XCTestCase {
    func testCancelReasonSheet_default() throws {
        try assertAuthSnapshot(
            CancelReasonSheet(
                viewModel: CancelReasonViewModel(
                    bookingID: SampleData.activeBookingID.uuidString,
                    bookingRepository: CancelReasonBookingRepositoryDouble()
                )
            ),
            named: "testCancelReasonSheet_default",
            size: CGSize(width: 393, height: 720)
        )
    }

    func testCancelReasonSheet_otherSelected() throws {
        let viewModel = CancelReasonViewModel(
            bookingID: SampleData.activeBookingID.uuidString,
            bookingRepository: CancelReasonBookingRepositoryDouble(),
            selectedReason: .other,
            freeText: "Need to reschedule after the vet changed our appointment."
        )

        try assertAuthSnapshot(
            CancelReasonSheet(viewModel: viewModel),
            named: "testCancelReasonSheet_otherSelected",
            size: CGSize(width: 393, height: 820)
        )
    }
}
