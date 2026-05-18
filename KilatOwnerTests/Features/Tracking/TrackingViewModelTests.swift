import XCTest
@testable import KilatOwner

@MainActor
final class TrackingViewModelTests: XCTestCase {
    func testTrackingVM_onAppear_subscribesAndTransitionsToConnected() {
        let repository = TrackingRepositoryDouble()
        let viewModel = makeViewModel(repository: repository)

        viewModel.onAppear()

        XCTAssertEqual(repository.subscribeCalls, [SampleData.activeBookingID.uuidString])
        XCTAssertEqual(viewModel.connectionState, .connected)
    }

    func testTrackingVM_locationUpdate_updatesRunnerPosition() async {
        let repository = TrackingRepositoryDouble()
        let viewModel = makeViewModel(repository: repository)
        viewModel.onAppear()

        let update = Self.locationUpdate(
            latitude: SampleData.pickupAddress.latitude + 0.002,
            longitude: SampleData.pickupAddress.longitude - 0.002,
            speedKmh: 32,
            headingDegrees: 95
        )
        repository.emit(.location(update))
        await Task.yield()

        XCTAssertEqual(viewModel.runnerCoordinate, Coordinate(lat: update.latitude, lng: update.longitude))
        XCTAssertEqual(viewModel.runnerSpeedKmh, 32)
        XCTAssertEqual(viewModel.headingDegrees, 95)
        XCTAssertEqual(viewModel.connectionState, .connected)
    }

    func testTrackingVM_disconnectThenReconnect_showsReconnectingBanner_thenClears() async {
        let repository = TrackingRepositoryDouble()
        let viewModel = makeViewModel(repository: repository)
        viewModel.onAppear()

        repository.disconnect()
        await Task.yield()

        XCTAssertEqual(viewModel.connectionState, .reconnecting)
        XCTAssertTrue(viewModel.showsReconnectingBanner)

        repository.emit(.location(Self.locationUpdate()))
        await Task.yield()

        XCTAssertEqual(viewModel.connectionState, .connected)
        XCTAssertFalse(viewModel.showsReconnectingBanner)
    }

    func testTrackingVM_chatTap_openExternalChatSession() {
        let viewModel = makeViewModel()

        viewModel.chatTapped()

        XCTAssertEqual(
            viewModel.externalURL?.absoluteString,
            "https://chat.kilat.test/bookings/\(SampleData.activeBookingID.uuidString)"
        )
    }

    func testTrackingVM_callTap_dialsTel_runnerPhone() {
        let viewModel = makeViewModel()

        viewModel.callTapped()

        XCTAssertEqual(viewModel.externalURL?.absoluteString, "tel:+60123456788")
    }

    func testTrackingVM_onDisappear_unsubscribesCleanly() {
        let repository = TrackingRepositoryDouble()
        let viewModel = makeViewModel(repository: repository)
        viewModel.onAppear()

        viewModel.onDisappear()

        XCTAssertEqual(repository.activeSubscription?.cancelCallCount, 1)
        XCTAssertEqual(viewModel.connectionState, .disconnected)
    }

    static func locationUpdate(
        latitude: Double = SampleData.pickupAddress.latitude + 0.004,
        longitude: Double = SampleData.pickupAddress.longitude - 0.005,
        speedKmh: Double = 28,
        headingDegrees: Double = 110
    ) -> TrackingLocationUpdate {
        TrackingLocationUpdate(
            bookingID: SampleData.activeBookingID.uuidString,
            runnerID: Personas.aiman.id,
            latitude: latitude,
            longitude: longitude,
            speedKmh: speedKmh,
            headingDegrees: headingDegrees,
            timestamp: SampleData.baseDate.addingTimeInterval(3_000)
        )
    }

    private func makeViewModel(
        repository: TrackingRepositoryDouble = TrackingRepositoryDouble(),
        initialConnectionState: TrackingConnectionState = .disconnected,
        initialLocation: TrackingLocationUpdate? = nil
    ) -> TrackingViewModel {
        TrackingViewModel(
            bookingID: SampleData.activeBookingID.uuidString,
            booking: SampleData.activeBooking,
            trackingRepository: repository,
            initialConnectionState: initialConnectionState,
            initialLocation: initialLocation
        )
    }
}

private final class TrackingRepositoryDouble: TrackingRepository {
    private(set) var subscribeCalls: [String] = []
    private(set) var activeSubscription: TrackingSubscriptionDouble?
    private var onUpdate: (@Sendable (TrackingEvent) -> Void)?
    private var onDisconnect: (@Sendable () -> Void)?

    func subscribe(
        bookingID: String,
        onUpdate: @escaping @Sendable (TrackingEvent) -> Void,
        onDisconnect: @escaping @Sendable () -> Void
    ) -> TrackingSubscription {
        subscribeCalls.append(bookingID)
        self.onUpdate = onUpdate
        self.onDisconnect = onDisconnect

        let subscription = TrackingSubscriptionDouble()
        activeSubscription = subscription
        return subscription
    }

    func emit(_ event: TrackingEvent) {
        onUpdate?(event)
    }

    func disconnect() {
        onDisconnect?()
    }
}

private final class TrackingSubscriptionDouble: TrackingSubscription {
    private(set) var cancelCallCount = 0

    func cancel() {
        cancelCallCount += 1
    }
}
