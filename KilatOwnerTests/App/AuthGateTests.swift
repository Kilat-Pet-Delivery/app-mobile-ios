import XCTest
@testable import KilatOwner

@MainActor
final class AuthGateTests: XCTestCase {
    func testAuthGate_noTokens_routesToLogin() async {
        let tokenStore = InMemoryTokenStore()
        let session = AppSession()
        let service = AuthGateServiceDouble(profileResult: .success(SampleData.ownerProfile))
        let sleeper = SleepRecorder()
        let gate = makeGate(
            tokenStore: tokenStore,
            session: session,
            service: service,
            sleeper: sleeper
        )

        let route = await gate.resolveInitialRoute()

        XCTAssertEqual(route, .login)
        XCTAssertEqual(gate.state, .unauthenticated)
        XCTAssertNil(session.profile)
        XCTAssertNil(session.accessToken)
        XCTAssertEqual(service.profileCalls, 0)
        XCTAssertEqual(sleeper.calls, [200_000_000])
    }

    func testAuthGate_validToken_routesToHome_andCachesProfile() async {
        let tokenStore = InMemoryTokenStore(accessToken: "valid-access")
        let session = AppSession()
        let service = AuthGateServiceDouble(profileResult: .success(SampleData.ownerProfile))
        let gate = makeGate(tokenStore: tokenStore, session: session, service: service)

        let route = await gate.resolveInitialRoute()

        XCTAssertEqual(route, .home)
        XCTAssertEqual(gate.state, .authenticated)
        XCTAssertEqual(session.profile, SampleData.ownerProfile)
        XCTAssertEqual(session.accessToken, "valid-access")
        XCTAssertEqual(service.profileCalls, 1)
        XCTAssertEqual(service.refreshProfileCalls, 0)
    }

    func testAuthGate_stubServiceWithoutTokens_routesToHomeAndCachesPersona() async {
        let tokenStore = InMemoryTokenStore()
        let session = AppSession()
        let service = StubAuthGateService(tokenStore: tokenStore)
        let gate = makeGate(tokenStore: tokenStore, session: session, service: service)

        let route = await gate.resolveInitialRoute()

        XCTAssertEqual(route, .home)
        XCTAssertEqual(gate.state, .authenticated)
        XCTAssertEqual(session.profile, SampleData.ownerProfile)
        XCTAssertEqual(session.accessToken, "stub-access-token")
        XCTAssertEqual(tokenStore.accessToken(), "stub-access-token")
        XCTAssertEqual(tokenStore.refreshToken(), "stub-refresh-token")
    }

    func testAuthGate_start_setsInitialRouteAsRoot() async {
        let tokenStore = InMemoryTokenStore(accessToken: "valid-access")
        let session = AppSession()
        let service = AuthGateServiceDouble(profileResult: .success(SampleData.ownerProfile))
        let coordinator = RootCoordinator(path: [.signup])
        let gate = makeGate(tokenStore: tokenStore, session: session, service: service)

        await gate.start(coordinator: coordinator)

        XCTAssertEqual(coordinator.rootRoute, .home)
        XCTAssertTrue(coordinator.path.isEmpty)
    }

    func testAuthGate_expiredToken_attemptsRefresh_thenRoutesAccordingly() async {
        let tokenStore = InMemoryTokenStore(accessToken: "old-access", refreshToken: "old-refresh")
        let session = AppSession()
        let service = AuthGateServiceDouble(
            profileResult: .failure(APIError.unauthorized),
            refreshResult: .success(SampleData.ownerProfile),
            onRefresh: {
                try? tokenStore.saveAccessToken("new-access")
                try? tokenStore.saveRefreshToken("new-refresh")
            }
        )
        let gate = makeGate(tokenStore: tokenStore, session: session, service: service)

        let route = await gate.resolveInitialRoute()

        XCTAssertEqual(route, .home)
        XCTAssertEqual(gate.state, .authenticated)
        XCTAssertEqual(service.profileCalls, 1)
        XCTAssertEqual(service.refreshProfileCalls, 1)
        XCTAssertEqual(tokenStore.accessToken(), "new-access")
        XCTAssertEqual(tokenStore.refreshToken(), "new-refresh")
        XCTAssertEqual(session.profile, SampleData.ownerProfile)
        XCTAssertEqual(session.accessToken, "new-access")
    }

    func testAuthGate_logout_clearsKeychainSessionAndRoutesToLogin() async {
        let tokenStore = InMemoryTokenStore(accessToken: "access", refreshToken: "refresh")
        let session = AppSession(profile: SampleData.ownerProfile, accessToken: "access", activeBookingID: "booking-1")
        let service = AuthGateServiceDouble(profileResult: .success(SampleData.ownerProfile))
        let coordinator = RootCoordinator(path: [.home, .tracking(bookingID: "booking-1")])
        let gate = makeGate(tokenStore: tokenStore, session: session, service: service)

        await gate.logout(coordinator: coordinator)

        XCTAssertEqual(service.logoutCalls, 1)
        XCTAssertNil(tokenStore.accessToken())
        XCTAssertNil(tokenStore.refreshToken())
        XCTAssertNil(session.profile)
        XCTAssertNil(session.accessToken)
        XCTAssertNil(session.activeBookingID)
        XCTAssertEqual(coordinator.rootRoute, .login)
        XCTAssertTrue(coordinator.path.isEmpty)
        XCTAssertEqual(gate.state, .unauthenticated)
    }

    private func makeGate(
        tokenStore: TokenStore,
        session: AppSession,
        service: AuthGateServicing,
        sleeper: SleepRecorder = SleepRecorder()
    ) -> AuthGate {
        AuthGate(
            tokenStore: tokenStore,
            session: session,
            service: service,
            sleep: sleeper.sleep
        )
    }
}

private final class AuthGateServiceDouble: AuthGateServicing {
    private let profileResult: Result<ProfileDTO, Error>
    private let refreshResult: Result<ProfileDTO, Error>
    private let onRefresh: () -> Void

    private(set) var profileCalls = 0
    private(set) var refreshProfileCalls = 0
    private(set) var logoutCalls = 0

    init(
        profileResult: Result<ProfileDTO, Error>,
        refreshResult: Result<ProfileDTO, Error> = .failure(APIError.unauthorized),
        onRefresh: @escaping () -> Void = {}
    ) {
        self.profileResult = profileResult
        self.refreshResult = refreshResult
        self.onRefresh = onRefresh
    }

    func profile() async throws -> ProfileDTO {
        profileCalls += 1
        return try profileResult.get()
    }

    func refreshProfile() async throws -> ProfileDTO {
        refreshProfileCalls += 1
        onRefresh()
        return try refreshResult.get()
    }

    func logout() async {
        logoutCalls += 1
    }
}

private final class SleepRecorder {
    private(set) var calls: [UInt64] = []

    func sleep(_ nanoseconds: UInt64) async throws {
        calls.append(nanoseconds)
    }
}
