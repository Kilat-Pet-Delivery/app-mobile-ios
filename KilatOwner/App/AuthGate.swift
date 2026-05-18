import Foundation
import Observation

protocol AuthGateServicing {
    var requiresStoredToken: Bool { get }

    func profile() async throws -> ProfileDTO
    func refreshProfile() async throws -> ProfileDTO
    func logout() async
}

extension AuthGateServicing {
    var requiresStoredToken: Bool { true }
}

struct StubAuthGateService: AuthGateServicing {
    let requiresStoredToken = false

    private let tokenStore: TokenStore

    init(tokenStore: TokenStore) {
        self.tokenStore = tokenStore
    }

    func profile() async throws -> ProfileDTO {
        try? tokenStore.saveAccessToken("stub-access-token")
        try? tokenStore.saveRefreshToken("stub-refresh-token")
        return SampleData.ownerProfile
    }

    func refreshProfile() async throws -> ProfileDTO {
        try await profile()
    }

    func logout() async {
        tokenStore.clear()
    }
}

struct LiveAuthGateService: AuthGateServicing {
    private let apiClient: APIClient
    private let tokenStore: TokenStore
    private let authRepository: AuthRepository
    private let interceptor: AuthInterceptor

    init(
        apiClient: APIClient,
        tokenStore: TokenStore,
        authRepository: AuthRepository
    ) {
        self.apiClient = apiClient
        self.tokenStore = tokenStore
        self.authRepository = authRepository
        self.interceptor = AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore)
    }

    func profile() async throws -> ProfileDTO {
        try await apiClient.get(Endpoints.Auth.profile)
    }

    func refreshProfile() async throws -> ProfileDTO {
        let tokenPair = try await interceptor.refreshTokens()
        return try await apiClient.get(Endpoints.Auth.profile, tokenOverride: tokenPair.accessToken)
    }

    func logout() async {
        try? await authRepository.logout()
        tokenStore.clear()
    }
}

@MainActor
@Observable
final class AuthGate {
    enum State: Equatable {
        case idle
        case checking
        case authenticated
        case unauthenticated
    }

    typealias Sleeper = (UInt64) async throws -> Void

    private(set) var state: State = .idle

    private let tokenStore: TokenStore
    private let session: AppSession
    private let service: AuthGateServicing
    private let minimumSplashNanoseconds: UInt64
    private let sleep: Sleeper
    private var hasStarted = false

    init(
        environment: AppEnvironment,
        minimumSplashNanoseconds: UInt64 = 200_000_000,
        sleep: @escaping Sleeper = { try await Task.sleep(nanoseconds: $0) }
    ) {
        self.tokenStore = environment.tokenStore
        self.session = environment.currentSession
        self.service = environment.authGateService
        self.minimumSplashNanoseconds = minimumSplashNanoseconds
        self.sleep = sleep
    }

    init(
        tokenStore: TokenStore,
        session: AppSession,
        service: AuthGateServicing,
        minimumSplashNanoseconds: UInt64 = 200_000_000,
        sleep: @escaping Sleeper = { try await Task.sleep(nanoseconds: $0) }
    ) {
        self.tokenStore = tokenStore
        self.session = session
        self.service = service
        self.minimumSplashNanoseconds = minimumSplashNanoseconds
        self.sleep = sleep
    }

    func start(coordinator: RootCoordinator) async {
        guard !hasStarted else { return }
        hasStarted = true

        let route = await resolveInitialRoute()
        coordinator.popToRoot()
        coordinator.push(route)
    }

    func resolveInitialRoute() async -> OwnerRoute {
        state = .checking

        let authTask = Task { await resolveAuthRoute() }
        try? await sleep(minimumSplashNanoseconds)
        let route = await authTask.value

        state = route == .home ? .authenticated : .unauthenticated
        return route
    }

    func logout(coordinator: RootCoordinator) async {
        await service.logout()
        tokenStore.clear()
        session.clear()
        state = .unauthenticated
        hasStarted = true
        coordinator.popToRoot()
        coordinator.push(.login)
    }

    private func resolveAuthRoute() async -> OwnerRoute {
        guard
            !service.requiresStoredToken
                || tokenStore.accessToken() != nil
                || tokenStore.refreshToken() != nil
        else {
            tokenStore.clear()
            session.clear()
            return .login
        }

        do {
            let profile = try await service.profile()
            session.cache(profile: profile, accessToken: tokenStore.accessToken())
            return .home
        } catch APIError.unauthorized {
            return await resolveAfterRefresh()
        } catch {
            tokenStore.clear()
            session.clear()
            return .login
        }
    }

    private func resolveAfterRefresh() async -> OwnerRoute {
        do {
            let profile = try await service.refreshProfile()
            session.cache(profile: profile, accessToken: tokenStore.accessToken())
            return .home
        } catch {
            tokenStore.clear()
            session.clear()
            return .login
        }
    }
}
