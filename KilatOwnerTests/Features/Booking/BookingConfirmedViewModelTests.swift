import XCTest
@testable import KilatOwner

@MainActor
final class BookingConfirmedViewModelTests: XCTestCase {
    func testBookingConfirmedVM_initialETA_displayedFromBookingDTO() {
        let viewModel = makeViewModel(booking: Self.booking(etaMinutes: 8))

        XCTAssertEqual(viewModel.etaMinutes, 8)
        XCTAssertEqual(viewModel.etaDisplayText, "8 min away")
        XCTAssertFalse(viewModel.isLateRunner)
    }

    func testBookingConfirmedVM_etaRefresh_updatesValue_every30s() async throws {
        var refreshCalls = 0
        let viewModel = makeViewModel(
            booking: Self.booking(etaMinutes: 8),
            refreshIntervalNanoseconds: 1_000_000,
            etaProvider: {
                refreshCalls += 1
                return 12
            }
        )

        viewModel.startETARefresh()
        try await waitForETA(viewModel, expected: 12)
        viewModel.stopETARefresh()

        XCTAssertGreaterThanOrEqual(refreshCalls, 1)
        XCTAssertEqual(viewModel.etaMinutes, 12)
        XCTAssertTrue(viewModel.isLateRunner)
    }

    func testBookingConfirmedVM_trackTap_pushesTrackingRoute() {
        let coordinator = RootCoordinator()
        let viewModel = makeViewModel(coordinator: coordinator)

        viewModel.trackTapped()

        XCTAssertEqual(coordinator.path, [.tracking(bookingID: SampleData.activeBookingID.uuidString)])
    }

    func testBookingConfirmedVM_cancelTap_presentsCancelSheet() {
        let viewModel = makeViewModel()

        viewModel.cancelTapped()

        XCTAssertTrue(viewModel.showsCancelReasonSheet)
    }

    static func booking(etaMinutes: Int) -> BookingDTO {
        let base = SampleData.activeBooking
        let routeSpec = RouteSpecDTO(
            pickupLat: base.routeSpec?.pickupLat ?? base.pickupAddress.latitude,
            pickupLng: base.routeSpec?.pickupLng ?? base.pickupAddress.longitude,
            dropoffLat: base.routeSpec?.dropoffLat ?? base.dropoffAddress.latitude,
            dropoffLng: base.routeSpec?.dropoffLng ?? base.dropoffAddress.longitude,
            distanceKm: base.routeSpec?.distanceKm ?? 4.8,
            estimatedDurationMin: etaMinutes,
            polyline: base.routeSpec?.polyline ?? "stub-route"
        )

        return BookingDTO(
            id: base.id,
            bookingNumber: base.bookingNumber,
            ownerID: base.ownerID,
            runnerID: base.runnerID,
            status: .accepted,
            petSpec: base.petSpec,
            crateRequirement: base.crateRequirement,
            pickupAddress: base.pickupAddress,
            dropoffAddress: base.dropoffAddress,
            routeSpec: routeSpec,
            estimatedPriceCents: base.estimatedPriceCents,
            finalPriceCents: base.finalPriceCents,
            currency: base.currency,
            scheduledAt: base.scheduledAt,
            pickedUpAt: nil,
            deliveredAt: nil,
            cancelledAt: nil,
            cancelNote: "",
            notes: base.notes,
            version: base.version,
            createdAt: base.createdAt,
            updatedAt: base.updatedAt
        )
    }

    private func makeViewModel(
        booking: BookingDTO? = nil,
        coordinator: RootCoordinator? = nil,
        refreshIntervalNanoseconds: UInt64 = 30_000_000_000,
        etaProvider: @escaping @MainActor () async -> Int? = { nil }
    ) -> BookingConfirmedViewModel {
        let booking = booking ?? Self.booking(etaMinutes: 8)

        return BookingConfirmedViewModel(
            bookingID: booking.id.uuidString,
            booking: booking,
            bookingRepository: BookingConfirmedRepositoryDouble(booking: booking),
            coordinator: coordinator,
            refreshIntervalNanoseconds: refreshIntervalNanoseconds,
            etaProvider: etaProvider
        )
    }

    private func waitForETA(
        _ viewModel: BookingConfirmedViewModel,
        expected: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        for _ in 0..<20 {
            if viewModel.etaMinutes == expected {
                return
            }
            try await Task.sleep(nanoseconds: 5_000_000)
        }

        XCTFail("Expected ETA \(expected), got \(viewModel.etaMinutes)", file: file, line: line)
    }
}

private final class BookingConfirmedRepositoryDouble: BookingRepository {
    let booking: BookingDTO

    init(booking: BookingDTO) {
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
        booking
    }
}
