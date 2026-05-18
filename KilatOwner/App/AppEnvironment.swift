import Foundation
import Observation

@Observable
final class AppSession {
    var profile: ProfileDTO?
    var accessToken: String?
    var activeBookingID: String?

    init(
        profile: ProfileDTO? = nil,
        accessToken: String? = nil,
        activeBookingID: String? = nil
    ) {
        self.profile = profile
        self.accessToken = accessToken
        self.activeBookingID = activeBookingID
    }

    func cache(profile: ProfileDTO, accessToken: String?) {
        self.profile = profile
        self.accessToken = accessToken
    }

    func clear() {
        profile = nil
        accessToken = nil
        activeBookingID = nil
    }
}

struct AppEnvironment {
    let useStubs: Bool
    let tokenStore: TokenStore
    let currentSession: AppSession
    let repositories: AppRepositories
    let authGateService: AuthGateServicing

    init(
        useStubs: Bool,
        tokenStore: TokenStore = KeychainStore(),
        currentSession: AppSession = AppSession(),
        repositories: AppRepositories? = nil,
        authGateService: AuthGateServicing? = nil
    ) {
        self.useStubs = useStubs
        self.tokenStore = tokenStore
        self.currentSession = currentSession
        self.repositories = repositories ?? (useStubs ? .stubs() : .live(tokenStore: tokenStore))

        if let authGateService {
            self.authGateService = authGateService
        } else if useStubs {
            self.authGateService = StubAuthGateService(tokenStore: tokenStore)
        } else {
            let client = APIClient(tokenStore: tokenStore)
            self.authGateService = LiveAuthGateService(
                apiClient: client,
                tokenStore: tokenStore,
                authRepository: AuthRepositoryImpl(client: client, tokenStore: tokenStore)
            )
        }
    }

    static var current: AppEnvironment {
        AppEnvironment(useStubs: ProcessInfo.processInfo.environment["KILAT_OWNER_STUB"] == "1")
    }

    static let preview = AppEnvironment(useStubs: true)
}

struct AppRepositories {
    let authRepository: AuthRepository
    let homeRepository: HomeRepository
    let petRepository: PetRepository
    let bookingRepository: BookingRepository
    let paymentRepository: PaymentRepository
    let notificationRepository: NotificationRepository
    let trackingRepository: TrackingRepository

    static func stubs() -> AppRepositories {
        AppRepositories(
            authRepository: StubAuthRepository(),
            homeRepository: StubHomeRepository(),
            petRepository: StubPetRepository(),
            bookingRepository: StubBookingRepository(),
            paymentRepository: StubPaymentRepository(),
            notificationRepository: StubNotificationRepository(),
            trackingRepository: StubTrackingRepository()
        )
    }

    static func live(tokenStore: TokenStore) -> AppRepositories {
        let client = APIClient(tokenStore: tokenStore)
        return AppRepositories(
            authRepository: AuthRepositoryImpl(client: client, tokenStore: tokenStore),
            homeRepository: HomeRepositoryImpl(client: client),
            petRepository: PetRepositoryImpl(client: client),
            bookingRepository: BookingRepositoryImpl(client: client),
            paymentRepository: PaymentRepositoryImpl(client: client),
            notificationRepository: NotificationRepositoryImpl(client: client),
            trackingRepository: TrackingRepositoryImpl(tokenStore: tokenStore)
        )
    }
}
