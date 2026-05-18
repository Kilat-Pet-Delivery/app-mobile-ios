import Foundation
import Observation

enum TrackingConnectionState: Equatable, Sendable {
    case disconnected
    case connected
    case reconnecting

    var displayText: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connected:
            return "Live"
        case .reconnecting:
            return "Reconnecting"
        }
    }
}

@MainActor
@Observable
final class TrackingViewModel {
    let bookingID: String
    let runner: RunnerPersona

    var booking: BookingDTO
    var connectionState: TrackingConnectionState
    var runnerCoordinate: Coordinate
    var runnerSpeedKmh: Double
    var headingDegrees: Double
    var lastUpdatedAt: Date?
    var externalURL: URL?

    private let trackingRepository: TrackingRepository
    private let coordinator: RootCoordinator?
    private var subscription: TrackingSubscription?
    private var currentStatus: BookingStatus

    init(
        bookingID: String,
        booking: BookingDTO,
        trackingRepository: TrackingRepository,
        coordinator: RootCoordinator? = nil,
        runner: RunnerPersona = Personas.aiman,
        initialConnectionState: TrackingConnectionState = .disconnected,
        initialLocation: TrackingLocationUpdate? = nil
    ) {
        self.bookingID = bookingID
        self.booking = booking
        self.trackingRepository = trackingRepository
        self.coordinator = coordinator
        self.runner = runner
        self.connectionState = initialConnectionState
        self.currentStatus = booking.status

        if let initialLocation {
            self.runnerCoordinate = Coordinate(lat: initialLocation.latitude, lng: initialLocation.longitude)
            self.runnerSpeedKmh = initialLocation.speedKmh
            self.headingDegrees = initialLocation.headingDegrees
            self.lastUpdatedAt = initialLocation.timestamp
        } else {
            self.runnerCoordinate = Self.defaultRunnerCoordinate(for: booking)
            self.runnerSpeedKmh = 0
            self.headingDegrees = 0
            self.lastUpdatedAt = nil
        }
    }

    var pickupCoordinate: Coordinate {
        Coordinate(
            lat: booking.routeSpec?.pickupLat ?? booking.pickupAddress.latitude,
            lng: booking.routeSpec?.pickupLng ?? booking.pickupAddress.longitude
        )
    }

    var dropoffCoordinate: Coordinate {
        Coordinate(
            lat: booking.routeSpec?.dropoffLat ?? booking.dropoffAddress.latitude,
            lng: booking.routeSpec?.dropoffLng ?? booking.dropoffAddress.longitude
        )
    }

    var etaText: String {
        let minutes = max(1, booking.routeSpec?.estimatedDurationMin ?? 10)
        return minutes == 1 ? "Now" : "\(minutes) min"
    }

    var speedText: String {
        guard runnerSpeedKmh > 0 else { return "Speed pending" }
        return "\(Int(runnerSpeedKmh.rounded())) km/h"
    }

    var statusText: String {
        currentStatus.displayLabel
    }

    var showsReconnectingBanner: Bool {
        connectionState == .reconnecting
    }

    func onAppear() {
        guard subscription == nil else { return }

        connectionState = .connected
        subscription = trackingRepository.subscribe(
            bookingID: bookingID,
            onUpdate: { [weak self] event in
                Task { @MainActor in
                    self?.handle(event)
                }
            },
            onDisconnect: { [weak self] in
                Task { @MainActor in
                    self?.handleDisconnect()
                }
            }
        )
    }

    func onDisappear() {
        subscription?.cancel()
        subscription = nil
        connectionState = .disconnected
    }

    func chatTapped() {
        externalURL = URL(string: "https://chat.kilat.test/bookings/\(bookingID)")
    }

    func callTapped() {
        let dialableNumber = runner.phoneNumber.filter { $0.isNumber || $0 == "+" }
        externalURL = URL(string: "tel:\(dialableNumber)")
    }

    func backTapped() {
        coordinator?.pop()
    }

    private func handle(_ event: TrackingEvent) {
        switch event {
        case .location(let update):
            guard update.bookingID == bookingID else { return }
            runnerCoordinate = Coordinate(lat: update.latitude, lng: update.longitude)
            runnerSpeedKmh = update.speedKmh
            headingDegrees = update.headingDegrees
            lastUpdatedAt = update.timestamp
            connectionState = .connected
        case .status(let event):
            guard event.bookingID == bookingID else { return }
            currentStatus = event.newStatus
            connectionState = .connected
        }
    }

    private func handleDisconnect() {
        connectionState = .reconnecting
    }

    private static func defaultRunnerCoordinate(for booking: BookingDTO) -> Coordinate {
        Coordinate(
            lat: booking.routeSpec?.pickupLat ?? booking.pickupAddress.latitude,
            lng: booking.routeSpec?.pickupLng ?? booking.pickupAddress.longitude
        )
    }
}
