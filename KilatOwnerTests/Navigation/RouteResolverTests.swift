import XCTest
@testable import KilatOwner

@MainActor
final class RouteResolverTests: XCTestCase {
    func testRouteResolver_returnsLoginView_forLoginRoute() {
        XCTAssertEqual(RouteResolver.resolvedView(for: .login), .loginView)
    }

    func testRouteResolver_returnsForgotPasswordView_forForgotPasswordRoute() {
        XCTAssertEqual(RouteResolver.resolvedView(for: .forgotPassword), .forgotPasswordView)
    }

    func testRouteResolver_returnsResetSentView_forResetSentRoute() {
        XCTAssertEqual(RouteResolver.resolvedView(for: .resetSent), .resetSentView)
    }

    func testRouteResolver_returnsSignupView_forSignupRoute() {
        XCTAssertEqual(RouteResolver.resolvedView(for: .signup), .signupView)
    }

    func testRouteResolver_returnsWelcomeView_forWelcomeRoute() {
        XCTAssertEqual(RouteResolver.resolvedView(for: .welcome), .welcomeView)
    }

    func testRouteResolver_returnsHomeView_forHomeRoute() {
        XCTAssertEqual(RouteResolver.resolvedView(for: .home), .homeView)
    }

    func testRouteResolver_returnsServicesView_forServicesRoute() {
        XCTAssertEqual(
            RouteResolver.resolvedView(for: .services(prefilledPetID: SampleData.mochiID.uuidString)),
            .servicesView
        )
    }

    func testRouteResolver_returnsBookingDetailView_forBookingDetailRoute() {
        XCTAssertEqual(
            RouteResolver.resolvedView(for: .bookingDetail(bookingID: SampleData.activeBookingID.uuidString)),
            .bookingDetailView
        )
    }

    func testRouteResolver_returnsBookingConfirmedView_forBookingConfirmedRoute() {
        XCTAssertEqual(
            RouteResolver.resolvedView(for: .bookingConfirmed(bookingID: SampleData.activeBookingID.uuidString)),
            .bookingConfirmedView
        )
    }

    func testRouteResolver_returnsCancelReasonSheet_forCancelReasonRoute() {
        XCTAssertEqual(
            RouteResolver.resolvedView(for: .cancelReason(bookingID: SampleData.activeBookingID.uuidString)),
            .cancelReasonSheet
        )
    }

    func testRouteResolver_returnsTrackingView_forTrackingRoute() {
        XCTAssertEqual(
            RouteResolver.resolvedView(for: .tracking(bookingID: SampleData.activeBookingID.uuidString)),
            .trackingView
        )
    }

    func testRouteResolver_returnsNotificationsView_forNotificationsRoute() {
        XCTAssertEqual(RouteResolver.resolvedView(for: .notifications), .notificationsView)
    }

    func testRouteResolver_returnsPushNotificationsView_forPushPreviewRoute() {
        XCTAssertEqual(RouteResolver.resolvedView(for: .pushPreview), .pushNotificationsView)
    }

    func testDeepLinkParser_bookingStatusChanged_routesToBookingDetail() {
        XCTAssertEqual(
            DeepLinkParser.route(for: notification(type: .bookingStatusChanged), bookingIDResolver: bookingID),
            .bookingDetail(bookingID: SampleData.activeBookingID.uuidString)
        )
    }

    func testDeepLinkParser_runnerAssigned_routesToBookingConfirmed() {
        XCTAssertEqual(
            DeepLinkParser.route(for: notification(type: .runnerAssigned), bookingIDResolver: bookingID),
            .bookingConfirmed(bookingID: SampleData.activeBookingID.uuidString)
        )
    }

    func testDeepLinkParser_chatMessage_routesToTracking() {
        XCTAssertEqual(
            DeepLinkParser.route(for: notification(type: .chatMessage), bookingIDResolver: bookingID),
            .tracking(bookingID: SampleData.activeBookingID.uuidString)
        )
    }

    private func bookingID(for notification: NotificationDTO) -> String {
        SampleData.activeBookingID.uuidString
    }

    private func notification(type: NotificationKind) -> NotificationDTO {
        NotificationDTO(
            id: "notification-\(type.rawValue)",
            type: type,
            title: "Booking update",
            body: "Mochi's trip status changed.",
            createdAt: SampleData.baseDate,
            readAt: nil
        )
    }
}
