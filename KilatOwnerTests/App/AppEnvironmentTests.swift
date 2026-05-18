import XCTest
@testable import KilatOwner

final class AppEnvironmentTests: XCTestCase {
    func testAppEnvironment_useStubs_returnsStubRepos() {
        let environment = AppEnvironment(
            useStubs: true,
            tokenStore: InMemoryTokenStore()
        )

        XCTAssertTrue(environment.repositories.authRepository is StubAuthRepository)
        XCTAssertTrue(environment.repositories.homeRepository is StubHomeRepository)
        XCTAssertTrue(environment.repositories.petRepository is StubPetRepository)
        XCTAssertTrue(environment.repositories.bookingRepository is StubBookingRepository)
        XCTAssertTrue(environment.repositories.paymentRepository is StubPaymentRepository)
        XCTAssertTrue(environment.repositories.notificationRepository is StubNotificationRepository)
        XCTAssertTrue(environment.repositories.trackingRepository is StubTrackingRepository)
        XCTAssertTrue(environment.authGateService is StubAuthGateService)
    }

    func testAppEnvironment_useStubsOff_returnsImplRepos() {
        let environment = AppEnvironment(
            useStubs: false,
            tokenStore: InMemoryTokenStore()
        )

        XCTAssertTrue(environment.repositories.authRepository is AuthRepositoryImpl)
        XCTAssertTrue(environment.repositories.homeRepository is HomeRepositoryImpl)
        XCTAssertTrue(environment.repositories.petRepository is PetRepositoryImpl)
        XCTAssertTrue(environment.repositories.bookingRepository is BookingRepositoryImpl)
        XCTAssertTrue(environment.repositories.paymentRepository is PaymentRepositoryImpl)
        XCTAssertTrue(environment.repositories.notificationRepository is NotificationRepositoryImpl)
        XCTAssertTrue(environment.repositories.trackingRepository is TrackingRepositoryImpl)
        XCTAssertTrue(environment.authGateService is LiveAuthGateService)
    }
}
