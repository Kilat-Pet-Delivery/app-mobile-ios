import XCTest
@testable import KilatOwner

final class KeychainStoreTests: XCTestCase {
    private var store: KeychainStore!

    override func setUp() {
        super.setUp()
        store = KeychainStore(serviceIdentifier: "my.kilat.KilatOwner.tests.\(UUID().uuidString)")
        store.clear()
    }

    override func tearDown() {
        store.clear()
        store = nil
        super.tearDown()
    }

    func testStoreLoadDelete_roundTrip() throws {
        try store.saveAccessToken("access-token")
        try store.saveRefreshToken("refresh-token")

        XCTAssertEqual(store.accessToken(), "access-token")
        XCTAssertEqual(store.refreshToken(), "refresh-token")

        store.clear()

        XCTAssertNil(store.accessToken())
        XCTAssertNil(store.refreshToken())
    }
}
