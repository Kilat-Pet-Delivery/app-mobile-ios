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
    func detail(id: String) async throws -> ActiveBookingSummary
}

struct MissingBookingRepository: HomeBookingRepositoryProtocol {
    func detail(id: String) async throws -> ActiveBookingSummary {
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
        bookingRepository: HomeBookingRepositoryProtocol = MissingBookingRepository()
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
            activeBooking = try await bookingRepository.detail(id: bookingId)
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    func logout() {
        authRepository.logout()
        appSession.logout()
    }
}
