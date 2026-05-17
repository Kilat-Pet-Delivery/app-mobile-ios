import Foundation
import XCTest
@testable import KilatOwner

final class AuthInterceptorTests: XCTestCase {
    private var tokenStore: InMemoryTokenStore!
    private var interceptor: AuthInterceptor!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)

        tokenStore = InMemoryTokenStore(accessToken: "old-access", refreshToken: "old-refresh")
        let client = APIClient(
            baseURL: URL(string: "https://example.test")!,
            session: session,
            tokenStore: tokenStore
        )
        interceptor = AuthInterceptor(apiClient: client, tokenStore: tokenStore)
    }

    override func tearDown() {
        interceptor = nil
        tokenStore = nil
        MockURLProtocol.reset()
        super.tearDown()
    }

    func testRefresh_swapsTokens_andRetriesOriginalRequest() async throws {
        var profileCallCount = 0
        MockURLProtocol.requestHandler = { request in
            if request.url?.path == "/api/v1/auth/refresh" {
                return Self.jsonResponse(
                    request: request,
                    body: #"{"success":true,"data":{"access_token":"new-access","refresh_token":"new-refresh"}}"#
                )
            }

            profileCallCount += 1
            if profileCallCount == 1 {
                return Self.emptyResponse(request: request, statusCode: 401)
            }

            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer new-access")
            return Self.jsonResponse(request: request, body: #"{"success":true,"data":{"name":"Mei Ling"}}"#)
        }

        let payload: TestProfile = try await interceptor.get(Endpoints.Auth.profile)

        XCTAssertEqual(payload.name, "Mei Ling")
        XCTAssertEqual(tokenStore.accessToken(), "new-access")
        XCTAssertEqual(tokenStore.refreshToken(), "new-refresh")
    }

    private static func jsonResponse(request: URLRequest, body: String) -> (HTTPURLResponse, Data?) {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (response, body.data(using: .utf8))
    }

    private static func emptyResponse(request: URLRequest, statusCode: Int) -> (HTTPURLResponse, Data?) {
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        return (response, Data())
    }
}

private struct TestProfile: Decodable, Equatable {
    let name: String
}
