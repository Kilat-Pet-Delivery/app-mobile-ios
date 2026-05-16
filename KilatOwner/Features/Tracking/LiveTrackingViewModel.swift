import CoreLocation
import Foundation
import Observation

@Observable
final class LiveTrackingViewModel {
    let bookingId: String
    private(set) var runnerCoordinate: CLLocationCoordinate2D?
    private(set) var polylinePoints: [CLLocationCoordinate2D] = []
    private(set) var pickupCoord: CLLocationCoordinate2D?
    private(set) var dropoffCoord: CLLocationCoordinate2D?
    private(set) var status: BookingStatus?
    private(set) var isConnected = false
    var errorMessage: String?
    var shouldDismiss = false

    @ObservationIgnored private let trackingRepository: TrackingRepositoryProtocol
    @ObservationIgnored private let bookingRepository: BookingRepositoryProtocol
    @ObservationIgnored private let tokenStore: TokenStore
    @ObservationIgnored private let appSession: AppSession
    @ObservationIgnored private var streamTask: Task<Void, Never>?
    @ObservationIgnored private var pollTask: Task<Void, Never>?

    // TrackingRepository (which wraps WebSocketClient) is @MainActor; default-arg
    // pattern doesn't bridge actor isolation, so use optional + nil-coalesce inside
    // a @MainActor init body.
    @MainActor
    init(
        bookingId: String,
        appSession: AppSession,
        trackingRepository: TrackingRepositoryProtocol? = nil,
        bookingRepository: BookingRepositoryProtocol? = nil,
        tokenStore: TokenStore = KeychainStore()
    ) {
        self.bookingId = bookingId
        self.appSession = appSession
        self.trackingRepository = trackingRepository ?? TrackingRepository()
        self.bookingRepository = bookingRepository ?? BookingRepository()
        self.tokenStore = tokenStore
    }

    @MainActor
    func onAppear() async {
        await loadBooking()
        await subscribe()
        startFallbackPolling()
    }

    func onDisappear() {
        streamTask?.cancel()
        pollTask?.cancel()
    }

    @MainActor
    private func loadBooking() async {
        do {
            let booking = try await bookingRepository.detail(id: bookingId)
            apply(booking: booking)
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    @MainActor
    private func subscribe() async {
        guard let token = tokenStore.accessToken() else {
            errorMessage = NetworkError.unauthorized.userMessage
            return
        }

        do {
            let stream = try await trackingRepository.subscribe(bookingId: bookingId, token: token)
            isConnected = true
            streamTask = Task { [weak self] in
                for await event in stream {
                    await self?.apply(event: event)
                }
            }
        } catch let error as NetworkError {
            isConnected = false
            errorMessage = error.userMessage
        } catch {
            isConnected = false
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    private func startFallbackPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                await self?.loadBooking()
            }
        }
    }

    @MainActor
    private func apply(event: TrackingEvent) {
        switch event {
        case let .location(update):
            let coordinate = CLLocationCoordinate2D(latitude: update.latitude, longitude: update.longitude)
            runnerCoordinate = coordinate
            polylinePoints.append(coordinate)
            if polylinePoints.count > 200 {
                polylinePoints.removeFirst(polylinePoints.count - 200)
            }
        case let .status(event):
            status = event.newStatus
            if event.newStatus == .delivered {
                completeAndDismiss()
            }
        }
    }

    @MainActor
    private func apply(booking: Booking) {
        pickupCoord = booking.pickupCoordinate
        dropoffCoord = booking.dropoffCoordinate
        status = booking.status
        if booking.status == .delivered {
            completeAndDismiss()
        }
    }

    @MainActor
    private func completeAndDismiss() {
        appSession.activeBookingId = nil
        shouldDismiss = true
    }
}
