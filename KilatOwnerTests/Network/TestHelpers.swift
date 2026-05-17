import XCTest
@testable import KilatOwner

final class InMemoryTokenStore: TokenStore {
    private var storedAccessToken: String?
    private var storedRefreshToken: String?

    init(accessToken: String? = nil, refreshToken: String? = nil) {
        storedAccessToken = accessToken
        storedRefreshToken = refreshToken
    }

    func saveAccessToken(_ token: String) throws {
        storedAccessToken = token
    }

    func accessToken() -> String? {
        storedAccessToken
    }

    func saveRefreshToken(_ token: String) throws {
        storedRefreshToken = token
    }

    func refreshToken() -> String? {
        storedRefreshToken
    }

    func clear() {
        storedAccessToken = nil
        storedRefreshToken = nil
    }
}

func XCTAssertThrowsAPIError(
    _ expectedError: APIError,
    operation: () async throws -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        try await operation()
        XCTFail("Expected \(expectedError)", file: file, line: line)
    } catch let error as APIError {
        XCTAssertEqual(error, expectedError, file: file, line: line)
    } catch {
        XCTFail("Expected \(expectedError), got \(error)", file: file, line: line)
    }
}
