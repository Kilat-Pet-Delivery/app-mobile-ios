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
    let authGateService: AuthGateServicing

    init(
        useStubs: Bool,
        tokenStore: TokenStore = KeychainStore(),
        currentSession: AppSession = AppSession(),
        authGateService: AuthGateServicing? = nil
    ) {
        self.useStubs = useStubs
        self.tokenStore = tokenStore
        self.currentSession = currentSession

        if let authGateService {
            self.authGateService = authGateService
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
