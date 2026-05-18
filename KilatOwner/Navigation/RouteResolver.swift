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
                    authRepository: environment.repositories.authRepository,
                    coordinator: coordinator,
                    onAuthenticated: { response in
                        environment.currentSession.cache(
                            profile: response.user,
                            accessToken: response.accessToken
                        )
                    }
                )
            )
        case .forgotPassword:
            ForgotPasswordView(
                viewModel: ForgotPasswordViewModel(
                    authRepository: environment.repositories.authRepository,
                    coordinator: coordinator
                )
            )
        case .resetSent:
            ResetSentView(coordinator: coordinator)
        case .signup:
            SignupView(
                viewModel: SignupViewModel(
                    authRepository: environment.repositories.authRepository,
                    coordinator: coordinator,
                    onAuthenticated: { response in
                        environment.currentSession.cache(
                            profile: response.user,
                            accessToken: response.accessToken
                        )
                    }
                )
            )
        case .welcome:
            WelcomeView(coordinator: coordinator)
        case .home:
            HomeView(
                viewModel: HomeViewModel(
                    homeRepository: environment.repositories.homeRepository,
                    coordinator: coordinator,
                    initialSnapshot: environment.useStubs ? SampleData.homeSnapshot : nil
                )
            )
        case .services(let prefilledPetID):
            ServicesView(
                viewModel: ServicesViewModel(
                    petRepository: environment.repositories.petRepository,
                    coordinator: coordinator,
                    prefilledPetID: prefilledPetID,
                    initialPets: environment.useStubs ? [SampleData.mochiPet, SampleData.baoPet] : nil
                )
            )
        case .bookingDetail(let bookingID):
            BookingDetailView(
                viewModel: BookingDetailViewModel(
                    bookingID: bookingID,
                    bookingRepository: environment.repositories.bookingRepository,
                    paymentRepository: environment.repositories.paymentRepository,
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
                    bookingRepository: environment.repositories.bookingRepository,
                    coordinator: coordinator
                )
            )
        case .cancelReason(let bookingID):
            CancelReasonSheet(
                viewModel: CancelReasonViewModel(
                    bookingID: bookingID,
                    bookingRepository: environment.repositories.bookingRepository
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
                    trackingRepository: environment.repositories.trackingRepository,
                    coordinator: coordinator
                )
            )
        case .notifications:
            NotificationsView(
                viewModel: NotificationsViewModel(
                    notificationRepository: environment.repositories.notificationRepository,
                    coordinator: coordinator
                )
            )
        case .pushPreview:
            PushNotificationsView()
        }
    }

    private static func bookingFixture(for bookingID: String) -> BookingDTO {
        bookingID == SampleData.completedBookingID.uuidString ? SampleData.completedBooking : SampleData.activeBooking
    }
}
