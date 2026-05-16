import XCTest
@testable import KilatOwner

final class APIEndpointTests: XCTestCase {
    func test_ownerEndpointMethods() {
        XCTAssertEqual(APIEndpoint.register.method, .post)
        XCTAssertEqual(APIEndpoint.login.method, .post)
        XCTAssertEqual(APIEndpoint.refresh.method, .post)
        XCTAssertEqual(APIEndpoint.logout.method, .post)
        XCTAssertEqual(APIEndpoint.profile.method, .get)
        XCTAssertEqual(APIEndpoint.petshopsList().method, .get)
        XCTAssertEqual(APIEndpoint.petshopDetail(id: "shop-1").method, .get)
        XCTAssertEqual(APIEndpoint.createBooking.method, .post)
        XCTAssertEqual(APIEndpoint.bookingDetail(id: "booking-1").method, .get)
        XCTAssertEqual(APIEndpoint.initiatePayment.method, .post)
        XCTAssertEqual(APIEndpoint.paymentByBooking(bookingId: "booking-1").method, .get)
    }

    func test_ownerEndpointPaths() {
        XCTAssertEqual(APIEndpoint.register.path, "auth/register")
        XCTAssertEqual(APIEndpoint.login.path, "auth/login")
        XCTAssertEqual(APIEndpoint.refresh.path, "auth/refresh")
        XCTAssertEqual(APIEndpoint.logout.path, "auth/logout")
        XCTAssertEqual(APIEndpoint.profile.path, "auth/profile")
        XCTAssertEqual(APIEndpoint.petshopsList().path, "petshops")
        XCTAssertEqual(APIEndpoint.petshopDetail(id: "shop-1").path, "petshops/shop-1")
        XCTAssertEqual(APIEndpoint.createBooking.path, "bookings")
        XCTAssertEqual(APIEndpoint.bookingDetail(id: "booking-1").path, "bookings/booking-1")
        XCTAssertEqual(APIEndpoint.initiatePayment.path, "payments/initiate")
        XCTAssertEqual(APIEndpoint.paymentByBooking(bookingId: "booking-1").path, "payments/booking/booking-1")
    }

    func test_ownerEndpointAuthRequirements() {
        XCTAssertFalse(APIEndpoint.register.requiresAuth)
        XCTAssertFalse(APIEndpoint.login.requiresAuth)
        XCTAssertFalse(APIEndpoint.refresh.requiresAuth)
        XCTAssertTrue(APIEndpoint.logout.requiresAuth)
        XCTAssertTrue(APIEndpoint.profile.requiresAuth)
        XCTAssertTrue(APIEndpoint.petshopsList().requiresAuth)
        XCTAssertTrue(APIEndpoint.petshopDetail(id: "shop-1").requiresAuth)
        XCTAssertTrue(APIEndpoint.createBooking.requiresAuth)
        XCTAssertTrue(APIEndpoint.bookingDetail(id: "booking-1").requiresAuth)
        XCTAssertTrue(APIEndpoint.initiatePayment.requiresAuth)
        XCTAssertTrue(APIEndpoint.paymentByBooking(bookingId: "booking-1").requiresAuth)
    }

    func test_petshopListQueryItems() {
        XCTAssertEqual(APIEndpoint.petshopsList().queryItems, [])
        XCTAssertEqual(APIEndpoint.petshopsList(category: "  ").queryItems, [])
        XCTAssertEqual(APIEndpoint.petshopsList(category: "grooming").queryItems, [
            URLQueryItem(name: "category", value: "grooming")
        ])
    }
}
