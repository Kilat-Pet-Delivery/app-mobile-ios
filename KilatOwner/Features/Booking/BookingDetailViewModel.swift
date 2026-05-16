import Foundation
import Observation

enum BookingPrimaryAction: Equatable {
    case pay
    case waiting
    case trackLive
    case completed
    case none
}

@Observable
final class BookingDetailViewModel {
    let bookingId: String
    private(set) var booking: Booking?
    private(set) var isLoading = false
    var errorMessage: String?

    var primaryAction: BookingPrimaryAction {
        guard let status = booking?.status else {
            return .none
        }

        switch status {
        case .awaitingPayment, .requested:
            return .pay
        case .awaitingRunner:
            return .waiting
        case .runnerAssigned, .accepted, .inProgress:
            return .trackLive
        case .delivered, .completed:
            return .completed
        case .cancelled:
            return .none
        }
    }

    @ObservationIgnored private let repository: BookingRepositoryProtocol

    init(bookingId: String, repository: BookingRepositoryProtocol = BookingRepository()) {
        self.bookingId = bookingId
        self.repository = repository
    }

    @MainActor
    func onAppear() async {
        guard booking == nil else {
            return
        }
        await refresh()
    }

    @MainActor
    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            booking = try await repository.detail(id: bookingId)
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }
}
