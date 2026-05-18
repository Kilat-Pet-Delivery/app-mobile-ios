import XCTest
@testable import KilatOwner

@MainActor
final class CancelReasonViewModelTests: XCTestCase {
    func testCancelReasonVM_initialState_noReasonSelected_submitDisabled() {
        let viewModel = makeViewModel()

        XCTAssertNil(viewModel.selectedReason)
        XCTAssertFalse(viewModel.isSubmitEnabled)
        XCTAssertFalse(viewModel.showsFreeTextField)
    }

    func testCancelReasonVM_selectReason_enablesSubmit() {
        let viewModel = makeViewModel()

        viewModel.selectReason(.changedMind)

        XCTAssertEqual(viewModel.selectedReason, .changedMind)
        XCTAssertTrue(viewModel.isSubmitEnabled)
        XCTAssertFalse(viewModel.showsFreeTextField)
    }

    func testCancelReasonVM_selectOther_revealsFreeTextField() {
        let viewModel = makeViewModel()

        viewModel.selectReason(.other)

        XCTAssertTrue(viewModel.isSubmitEnabled)
        XCTAssertTrue(viewModel.showsFreeTextField)
    }

    func testCancelReasonVM_submit_callsCancelWithSelectedReason() async {
        let repository = CancelReasonBookingRepositoryDouble()
        let viewModel = makeViewModel(repository: repository)

        viewModel.selectReason(.tookTooLong)
        await viewModel.submit()

        XCTAssertEqual(repository.cancelCalls, [
            .init(
                id: SampleData.activeBookingID.uuidString,
                reason: .tookTooLong,
                freeText: ""
            )
        ])
    }

    func testCancelReasonVM_submitOtherWithFreeText_passesFreeTextAsReason() async {
        let repository = CancelReasonBookingRepositoryDouble()
        let viewModel = makeViewModel(repository: repository)

        viewModel.selectReason(.other)
        viewModel.freeText = "My neighbour can help today."
        await viewModel.submit()

        XCTAssertEqual(repository.cancelCalls, [
            .init(
                id: SampleData.activeBookingID.uuidString,
                reason: .other,
                freeText: "My neighbour can help today."
            )
        ])
    }

    private func makeViewModel(
        repository: CancelReasonBookingRepositoryDouble = CancelReasonBookingRepositoryDouble()
    ) -> CancelReasonViewModel {
        CancelReasonViewModel(
            bookingID: SampleData.activeBookingID.uuidString,
            bookingRepository: repository
        )
    }
}

final class CancelReasonBookingRepositoryDouble: BookingRepository {
    struct CancelCall: Equatable {
        let id: String
        let reason: CancelReason
        let freeText: String
    }

    var cancelCalls: [CancelCall] = []
    var booking: BookingDTO

    init(booking: BookingDTO = SampleData.activeBooking) {
        self.booking = booking
    }

    func create(_ request: CreateBookingRequest) async throws -> BookingDTO {
        booking
    }

    func get(id: String) async throws -> BookingDTO {
        booking
    }

    func listActive() async throws -> [BookingDTO] {
        [booking]
    }

    func listRecent() async throws -> [BookingDTO] {
        [booking]
    }

    func cancel(id: String, reason: CancelReason, freeText: String) async throws -> BookingDTO {
        cancelCalls.append(CancelCall(id: id, reason: reason, freeText: freeText))
        return booking
    }
}
