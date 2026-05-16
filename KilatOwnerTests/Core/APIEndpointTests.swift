import XCTest
@testable import KilatOwner

final class APIEndpointTests: XCTestCase {
    func test_ownerEndpointMethods() {
        XCTAssertEqual(APIEndpoint.register.method, .post)
        XCTAssertEqual(APIEndpoint.login.method, .post)
        XCTAssertEqual(APIEndpoint.refresh.method, .post)
        XCTAssertEqual(APIEndpoint.me.method, .get)
        XCTAssertEqual(APIEndpoint.petshopsList().method, .get)
        XCTAssertEqual(APIEndpoint.petshopDetail(id: "shop-1").method, .get)
        XCTAssertEqual(APIEndpoint.createBooking.method, .post)
        XCTAssertEqual(APIEndpoint.bookingDetail(id: "booking-1").method, .get)
        XCTAssertEqual(APIEndpoint.initiatePayment.method, .post)
    }

    func test_ownerEndpointPaths() {
        XCTAssertEqual(APIEndpoint.register.path, "auth/register")
        XCTAssertEqual(APIEndpoint.login.path, "auth/login")
        XCTAssertEqual(APIEndpoint.refresh.path, "auth/refresh")
        XCTAssertEqual(APIEndpoint.me.path, "auth/me")
        XCTAssertEqual(APIEndpoint.petshopsList().path, "petshops")
        XCTAssertEqual(APIEndpoint.petshopDetail(id: "shop-1").path, "petshops/shop-1")
        XCTAssertEqual(APIEndpoint.createBooking.path, "bookings")
        XCTAssertEqual(APIEndpoint.bookingDetail(id: "booking-1").path, "bookings/booking-1")
        XCTAssertEqual(APIEndpoint.initiatePayment.path, "payments/initiate")
    }

    func test_ownerEndpointAuthRequirements() {
        XCTAssertFalse(APIEndpoint.register.requiresAuth)
        XCTAssertFalse(APIEndpoint.login.requiresAuth)
        XCTAssertFalse(APIEndpoint.refresh.requiresAuth)
        XCTAssertTrue(APIEndpoint.me.requiresAuth)
        XCTAssertTrue(APIEndpoint.petshopsList().requiresAuth)
        XCTAssertTrue(APIEndpoint.petshopDetail(id: "shop-1").requiresAuth)
        XCTAssertTrue(APIEndpoint.createBooking.requiresAuth)
        XCTAssertTrue(APIEndpoint.bookingDetail(id: "booking-1").requiresAuth)
        XCTAssertTrue(APIEndpoint.initiatePayment.requiresAuth)
    }

    func test_petshopListQueryItems() {
        XCTAssertEqual(APIEndpoint.petshopsList(page: 2).queryItems, [
            URLQueryItem(name: "page", value: "2")
        ])

        XCTAssertEqual(APIEndpoint.petshopsList(page: 3, query: "grooming").queryItems, [
            URLQueryItem(name: "page", value: "3"),
            URLQueryItem(name: "query", value: "grooming")
        ])
    }
}
