import XCTest
@testable import KilatOwner

final class AuthRepositoryImplTests: XCTestCase {
    private var tokenStore: InMemoryTokenStore!
    private var client: APIClient!
    private var repository: AuthRepositoryImpl!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)

        tokenStore = InMemoryTokenStore()
        client = APIClient(
            baseURL: URL(string: "https://example.test")!,
            session: session,
            tokenStore: tokenStore
        )
        repository = AuthRepositoryImpl(client: client, tokenStore: tokenStore)
    }

    override func tearDown() {
        repository = nil
        client = nil
        tokenStore = nil
        MockURLProtocol.reset()
        super.tearDown()
    }

    func testAuthRepoImpl_login_postsCorrectBody_andReturnsProfile() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/api/v1/auth/login")
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))

            let body = try Self.jsonBody(from: request)
            XCTAssertEqual(body["email"] as? String, "owner@kilat.my")
            XCTAssertEqual(body["password"] as? String, "password123")

            return Self.jsonResponse(request: request, body: Self.loginResponseJSON)
        }

        let response = try await repository.login(email: "owner@kilat.my", password: "password123")

        XCTAssertEqual(response.user.email, "owner@kilat.my")
        XCTAssertEqual(response.accessToken, "access-token")
        XCTAssertEqual(tokenStore.accessToken(), "access-token")
        XCTAssertEqual(tokenStore.refreshToken(), "refresh-token")
    }

    func testAuthRepoImpl_register_postsCombinedOwnerAndPetShape() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/api/v1/auth/register")

            let body = try Self.jsonBody(from: request)
            XCTAssertEqual(body["email"] as? String, "owner@kilat.my")
            XCTAssertEqual(body["phone"] as? String, "+60123456789")
            XCTAssertEqual(body["full_name"] as? String, "Mei Ling Chen")
            XCTAssertEqual(body["password"] as? String, "password123")
            XCTAssertEqual(body["role"] as? String, "owner")

            let firstPet = try XCTUnwrap(body["first_pet"] as? [String: Any])
            XCTAssertEqual(firstPet["pet_type"] as? String, "cat")
            XCTAssertEqual(firstPet["name"] as? String, "Mochi")
            let weightKg = try XCTUnwrap(firstPet["weight_kg"] as? Double)
            XCTAssertEqual(weightKg, 4.2, accuracy: 0.001)

            return Self.jsonResponse(request: request, body: Self.loginResponseJSON)
        }

        let request = RegisterRequest(
            email: "owner@kilat.my",
            phone: "+60123456789",
            fullName: "Mei Ling Chen",
            password: "password123",
            firstPet: RegisterPetRequest(petType: .cat, name: "Mochi", weightKg: 4.2)
        )

        let response = try await repository.register(request)

        XCTAssertEqual(response.user.fullName, "Mei Ling Chen")
        XCTAssertEqual(tokenStore.accessToken(), "access-token")
        XCTAssertEqual(tokenStore.refreshToken(), "refresh-token")
    }

    func testAuthRepoImpl_forgotPassword_postsEmailOnly() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/api/v1/auth/forgot-password")

            let body = try Self.jsonBody(from: request)
            XCTAssertEqual(body["email"] as? String, "owner@kilat.my")
            XCTAssertEqual(body.keys.count, 1)

            return Self.jsonResponse(request: request, body: Self.emptyResponseJSON)
        }

        try await repository.forgotPassword(email: "owner@kilat.my")
    }

    func testAuthRepoImpl_resetPassword_postsTokenAndNewPassword() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/api/v1/auth/reset-password")

            let body = try Self.jsonBody(from: request)
            XCTAssertEqual(body["token"] as? String, "reset-token")
            XCTAssertEqual(body["newPassword"] as? String, "newPassword123")
            XCTAssertEqual(body.keys.count, 2)

            return Self.jsonResponse(request: request, body: Self.emptyResponseJSON)
        }

        try await repository.resetPassword(token: "reset-token", newPassword: "newPassword123")
    }

    func testAuthRepoImpl_profile_get_decodesProfileDTO() async throws {
        try tokenStore.saveAccessToken("access-token")

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/api/v1/auth/profile")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer access-token")

            return Self.jsonResponse(request: request, body: Self.profileResponseJSON)
        }

        let profile = try await repository.profile()

        XCTAssertEqual(profile.email, "owner@kilat.my")
        XCTAssertEqual(profile.fullName, "Mei Ling Chen")
        XCTAssertEqual(profile.role, "owner")
        XCTAssertTrue(profile.isVerified)
    }

    func testAuthRepoImpl_logout_clearsKeychainOnSuccess() async throws {
        try tokenStore.saveAccessToken("access-token")
        try tokenStore.saveRefreshToken("refresh-token")

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/api/v1/auth/logout")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer access-token")

            return Self.jsonResponse(request: request, body: Self.emptyResponseJSON)
        }

        try await repository.logout()

        XCTAssertNil(tokenStore.accessToken())
        XCTAssertNil(tokenStore.refreshToken())
    }

    private static func jsonBody(from request: URLRequest) throws -> [String: Any] {
        let data = try XCTUnwrap(request.httpBody)
        let object = try JSONSerialization.jsonObject(with: data)
        return try XCTUnwrap(object as? [String: Any])
    }

    private static func jsonResponse(request: URLRequest, body: String) -> (HTTPURLResponse, Data?) {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (response, body.data(using: .utf8))
    }

    private static let emptyResponseJSON = #"{"success":true,"data":{}}"#

    private static let loginResponseJSON = """
    {
      "success": true,
      "data": {
        "access_token": "access-token",
        "refresh_token": "refresh-token",
        "user": \(profileJSON)
      }
    }
    """

    private static let profileResponseJSON = """
    {
      "success": true,
      "data": \(profileJSON)
    }
    """

    private static let profileJSON = """
    {
      "id": "00000000-0000-0000-0000-000000000001",
      "email": "owner@kilat.my",
      "phone": "+60123456789",
      "full_name": "Mei Ling Chen",
      "role": "owner",
      "is_verified": true,
      "avatar_url": null,
      "created_at": "2026-05-18T03:00:00Z"
    }
    """
}
