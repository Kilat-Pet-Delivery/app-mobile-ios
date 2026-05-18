import Foundation
import Observation

@MainActor
@Observable
final class BookingConfirmedViewModel {
    let bookingID: String
    let runner: RunnerPersona
    let refreshIntervalNanoseconds: UInt64

    var booking: BookingDTO
    var etaMinutes: Int
    var showsCancelReasonSheet: Bool
    var isRefreshingETA: Bool

    private let bookingRepository: BookingRepository
    private let coordinator: RootCoordinator?
    private let etaProvider: @MainActor () async -> Int?
    private var etaRefreshTask: Task<Void, Never>?

    init(
        bookingID: String,
        booking: BookingDTO,
        bookingRepository: BookingRepository,
        coordinator: RootCoordinator? = nil,
        runner: RunnerPersona = Personas.aiman,
        refreshIntervalNanoseconds: UInt64 = 30_000_000_000,
        etaProvider: @escaping @MainActor () async -> Int? = { nil }
    ) {
        self.bookingID = bookingID
        self.booking = booking
        self.bookingRepository = bookingRepository
        self.coordinator = coordinator
        self.runner = runner
        self.refreshIntervalNanoseconds = refreshIntervalNanoseconds
        self.etaProvider = etaProvider
        self.etaMinutes = max(1, booking.routeSpec?.estimatedDurationMin ?? 10)
        self.showsCancelReasonSheet = false
        self.isRefreshingETA = false
    }

    var etaDisplayText: String {
        if etaMinutes <= 1 {
            return "Arriving now"
        }

        return "\(etaMinutes) min away"
    }

    var isLateRunner: Bool {
        etaMinutes > 10
    }

    var routeSummaryText: String {
        guard let routeSpec = booking.routeSpec else {
            return "Route pending"
        }

        return String(format: "%.1f km route", routeSpec.distanceKm)
    }

    func startETARefresh() {
        guard etaRefreshTask == nil else { return }

        isRefreshingETA = true
        etaRefreshTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: refreshIntervalNanoseconds)
                } catch {
                    break
                }

                guard !Task.isCancelled else { break }
                await refreshETAOnce()
            }
        }
    }

    func stopETARefresh() {
        etaRefreshTask?.cancel()
        etaRefreshTask = nil
        isRefreshingETA = false
    }

    func refreshETAOnce() async {
        guard let refreshedETA = await etaProvider() else { return }
        etaMinutes = max(1, refreshedETA)
    }

    func trackTapped() {
        coordinator?.push(.tracking(bookingID: bookingID))
    }

    func cancelTapped() {
        showsCancelReasonSheet = true
    }

    func dismissCancelSheet() {
        showsCancelReasonSheet = false
    }

    func makeCancelReasonViewModel() -> CancelReasonViewModel {
        CancelReasonViewModel(
            bookingID: bookingID,
            bookingRepository: bookingRepository
        ) { [weak self] cancelledBooking in
            self?.booking = cancelledBooking
            self?.showsCancelReasonSheet = false
        }
    }
}
