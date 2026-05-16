import Foundation
import Observation

@Observable
final class SplashViewModel {
    private(set) var message = "Getting Kilat ready"

    @ObservationIgnored private let authRepository: AuthRepositoryProtocol
    @ObservationIgnored private let tokenStore: TokenStore
    @ObservationIgnored private let appSession: AppSession

    init(
        authRepository: AuthRepositoryProtocol,
        tokenStore: TokenStore,
        appSession: AppSession
    ) {
        self.authRepository = authRepository
        self.tokenStore = tokenStore
        self.appSession = appSession
    }

    convenience init(appSession: AppSession) {
        let tokenStore = KeychainStore()
        self.init(
            authRepository: AuthRepository(tokenStore: tokenStore),
            tokenStore: tokenStore,
            appSession: appSession
        )
    }

    @MainActor
    func bootstrap() async {
        guard tokenStore.accessToken() != nil else {
            appSession.markUnauthenticated()
            return
        }

        do {
            let user = try await authRepository.me()
            appSession.markAuthenticated(user: user)
        } catch NetworkError.unauthorized {
            await refreshAndLoadProfile()
        } catch {
            appSession.markUnauthenticated()
        }
    }

    @MainActor
    private func refreshAndLoadProfile() async {
        do {
            message = "Refreshing your session"
            try await authRepository.refresh()
            let user = try await authRepository.me()
            appSession.markAuthenticated(user: user)
        } catch {
            appSession.logout()
        }
    }
}
