import XCTest
@testable import KilatOwner

final class KilatOwnerTests: XCTestCase {
    func testAppSessionStartsUnauthenticated() {
        let session = AppSession()

        XCTAssertEqual(session.state, .unauthenticated)
    }
}
