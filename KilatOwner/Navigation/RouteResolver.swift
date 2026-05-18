import SwiftUI

@MainActor
enum RouteResolver {
    enum ResolvedView: Equatable {
        case loginView
        case forgotPasswordView
        case resetSentView
        case signupView
        case welcomeView
        case homeView
        case servicesView
        case bookingDetailView
        case bookingConfirmedView
        case cancelReasonSheet
        case trackingView
        case notificationsView
        case pushNotificationsView
    }

    static func resolvedView(for route: OwnerRoute) -> ResolvedView {
        switch route {
        case .login:
            return .loginView
        case .forgotPassword:
            return .forgotPasswordView
        case .resetSent:
            return .resetSentView
        case .signup:
            return .signupView
        case .welcome:
            return .welcomeView
        case .home:
            return .homeView
        case .services:
            return .servicesView
        case .bookingDetail:
            return .bookingDetailView
        case .bookingConfirmed:
            return .bookingConfirmedView
        case .cancelReason:
            return .cancelReasonSheet
        case .tracking:
            return .trackingView
        case .notifications:
            return .notificationsView
        case .pushPreview:
            return .pushNotificationsView
        }
    }

    @ViewBuilder
    static func view(
        for route: OwnerRoute,
        environment: AppEnvironment,
        coordinator: RootCoordinator
    ) -> some View {
        switch route {
        case .login:
            LoginView(
                viewModel: LoginViewModel(
                    authRepository: authRepository(environment: environment),
                    coordinator: coordinator
                )
            )
        case .forgotPassword:
            ForgotPasswordView(
                viewModel: ForgotPasswordViewModel(
                    authRepository: authRepository(environment: environment),
                    coordinator: coordinator
                )
            )
        case .resetSent:
            ResetSentView(coordinator: coordinator)
        case .signup:
            SignupView(
                viewModel: SignupViewModel(
                    authRepository: authRepository(environment: environment),
                    coordinator: coordinator
                )
            )
        case .welcome:
            WelcomeView(coordinator: coordinator)
        case .home:
            HomeView(
                viewModel: HomeViewModel(
                    homeRepository: homeRepository(environment: environment),
                    coordinator: coordinator,
                    initialSnapshot: environment.useStubs ? SampleData.homeSnapshot : nil
                )
            )
        case .services(let prefilledPetID):
            ServicesView(
                viewModel: ServicesViewModel(
                    petRepository: petRepository(environment: environment),
                    coordinator: coordinator,
                    prefilledPetID: prefilledPetID,
                    initialPets: environment.useStubs ? [SampleData.mochiPet, SampleData.baoPet] : nil
                )
            )
        case .bookingDetail(let bookingID):
            BookingDetailView(
                viewModel: BookingDetailViewModel(
                    bookingID: bookingID,
                    bookingRepository: bookingRepository(environment: environment),
                    paymentRepository: paymentRepository(environment: environment),
                    coordinator: coordinator,
                    initialBooking: environment.useStubs ? SampleData.activeBooking : nil,
                    initialPayment: environment.useStubs ? SampleData.payment : nil
                )
            )
        case .bookingConfirmed(let bookingID):
            BookingConfirmedView(
                viewModel: BookingConfirmedViewModel(
                    bookingID: bookingID,
                    booking: bookingFixture(for: bookingID),
                    bookingRepository: bookingRepository(environment: environment),
                    coordinator: coordinator
                )
            )
        case .cancelReason(let bookingID):
            CancelReasonSheet(
                viewModel: CancelReasonViewModel(
                    bookingID: bookingID,
                    bookingRepository: bookingRepository(environment: environment)
                ) { _ in
                    coordinator.pop()
                },
                onKeepBooking: {
                    coordinator.pop()
                }
            )
        case .tracking(let bookingID):
            TrackingView(
                viewModel: TrackingViewModel(
                    bookingID: bookingID,
                    booking: bookingFixture(for: bookingID),
                    trackingRepository: trackingRepository(environment: environment),
                    coordinator: coordinator
                )
            )
        case .notifications:
            NotificationsView(
                viewModel: NotificationsViewModel(
                    notificationRepository: notificationRepository(environment: environment),
                    coordinator: coordinator
                )
            )
        case .pushPreview:
            PushNotificationsView()
        }
    }

    private static func authRepository(environment: AppEnvironment) -> AuthRepository {
        guard !environment.useStubs else { return StubAuthRepository() }
        let tokenStore = KeychainStore()
        return AuthRepositoryImpl(client: APIClient(tokenStore: tokenStore), tokenStore: tokenStore)
    }

    private static func homeRepository(environment: AppEnvironment) -> HomeRepository {
        environment.useStubs ? StubHomeRepository() : HomeRepositoryImpl(client: authenticatedClient())
    }

    private static func petRepository(environment: AppEnvironment) -> PetRepository {
        environment.useStubs ? StubPetRepository() : PetRepositoryImpl(client: authenticatedClient())
    }

    private static func bookingRepository(environment: AppEnvironment) -> BookingRepository {
        environment.useStubs ? StubBookingRepository() : BookingRepositoryImpl(client: authenticatedClient())
    }

    private static func paymentRepository(environment: AppEnvironment) -> PaymentRepository {
        environment.useStubs ? StubPaymentRepository() : PaymentRepositoryImpl(client: authenticatedClient())
    }

    private static func notificationRepository(environment: AppEnvironment) -> NotificationRepository {
        environment.useStubs ? StubNotificationRepository() : NotificationRepositoryImpl(client: authenticatedClient())
    }

    private static func trackingRepository(environment: AppEnvironment) -> TrackingRepository {
        environment.useStubs ? StubTrackingRepository() : TrackingRepositoryImpl(tokenStore: KeychainStore())
    }

    private static func authenticatedClient() -> APIClient {
        APIClient(tokenStore: KeychainStore())
    }

    private static func bookingFixture(for bookingID: String) -> BookingDTO {
        bookingID == SampleData.completedBookingID.uuidString ? SampleData.completedBooking : SampleData.activeBooking
    }
}
