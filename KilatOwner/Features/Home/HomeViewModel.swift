import Foundation
import Observation

struct ActiveBookingSummary: Equatable, Identifiable {
    let id: String
    let status: String
    let petName: String
    let pickupAddress: String
    let dropoffAddress: String
}

protocol HomeBookingRepositoryProtocol {
    func detail(id: String) async throws -> Booking
}

struct MissingBookingRepository: HomeBookingRepositoryProtocol {
    func detail(id: String) async throws -> Booking {
        throw NetworkError.invalidResponse
    }
}

@Observable
final class HomeViewModel {
    private(set) var user: User?
    private(set) var activeBooking: ActiveBookingSummary?
    private(set) var isLoading = false
    var errorMessage: String?

    @ObservationIgnored private let appSession: AppSession
    @ObservationIgnored private let authRepository: AuthRepositoryProtocol
    @ObservationIgnored private let bookingRepository: HomeBookingRepositoryProtocol

    init(
        appSession: AppSession,
        authRepository: AuthRepositoryProtocol = AuthRepository(),
        bookingRepository: HomeBookingRepositoryProtocol = BookingRepository()
    ) {
        self.appSession = appSession
        self.authRepository = authRepository
        self.bookingRepository = bookingRepository
        self.user = appSession.currentUser
    }

    @MainActor
    func onAppear() async {
        user = appSession.currentUser

        guard let bookingId = appSession.activeBookingId else {
            activeBooking = nil
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let booking = try await bookingRepository.detail(id: bookingId)
            activeBooking = ActiveBookingSummary(booking: booking)
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    @MainActor
    func logout() async {
        await authRepository.logout()
        appSession.logout()
    }
}

extension BookingRepository: HomeBookingRepositoryProtocol {}

private extension ActiveBookingSummary {
    init(booking: Booking) {
        self.init(
            id: booking.id,
            status: booking.status.rawValue,
            petName: booking.petSpec.name,
            pickupAddress: booking.pickupAddress.singleLineLabel,
            dropoffAddress: booking.dropoffAddress.singleLineLabel
        )
    }
}
