import SwiftUI
import XCTest
@testable import KilatOwner

@MainActor
final class TrackingViewSnapshotTests: XCTestCase {
    func testTrackingView_connected() throws {
        try assertAuthSnapshot(
            TrackingView(
                viewModel: viewModel(
                    initialConnectionState: .connected,
                    initialLocation: TrackingViewModelTests.locationUpdate()
                ),
                subscribesOnAppear: false
            ),
            named: "testTrackingView_connected",
            size: CGSize(width: 393, height: 852)
        )
    }

    func testTrackingView_reconnectingBanner() throws {
        try assertAuthSnapshot(
            TrackingView(
                viewModel: viewModel(
                    initialConnectionState: .reconnecting,
                    initialLocation: TrackingViewModelTests.locationUpdate(speedKmh: 18)
                ),
                subscribesOnAppear: false
            ),
            named: "testTrackingView_reconnectingBanner",
            size: CGSize(width: 393, height: 852)
        )
    }

    private func viewModel(
        initialConnectionState: TrackingConnectionState,
        initialLocation: TrackingLocationUpdate
    ) -> TrackingViewModel {
        TrackingViewModel(
            bookingID: SampleData.activeBookingID.uuidString,
            booking: SampleData.activeBooking,
            trackingRepository: SnapshotTrackingRepository(),
            initialConnectionState: initialConnectionState,
            initialLocation: initialLocation
        )
    }
}

private final class SnapshotTrackingRepository: TrackingRepository {
    func subscribe(
        bookingID: String,
        onUpdate: @escaping @Sendable (TrackingEvent) -> Void,
        onDisconnect: @escaping @Sendable () -> Void
    ) -> TrackingSubscription {
        SnapshotTrackingSubscription()
    }
}

private struct SnapshotTrackingSubscription: TrackingSubscription {
    func cancel() {}
}
