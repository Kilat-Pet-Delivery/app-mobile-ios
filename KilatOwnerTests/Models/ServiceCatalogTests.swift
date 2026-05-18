import UIKit
import XCTest
@testable import KilatOwner

final class ServiceCatalogTests: XCTestCase {
    func testAll_hasSixEntries() {
        XCTAssertEqual(ServiceCatalog.all.count, 6)
    }

    func testAll_containsExpectedDesignEntries() {
        XCTAssertEqual(ServiceCatalog.all.map(\.id), [
            "vet",
            "grooming",
            "supplies",
            "boarding",
            "daycare",
            "emergency"
        ])
        XCTAssertEqual(ServiceCatalog.all.first?.name, "Vet visit")
        XCTAssertEqual(ServiceCatalog.all.last?.leadTimeHint, "ASAP")
    }

    func testAll_iconsAreValidSFSymbols() {
        for service in ServiceCatalog.all {
            XCTAssertNotNil(
                UIImage(systemName: service.iconSFSymbol),
                "\(service.iconSFSymbol) should be a valid SF Symbol"
            )
        }
    }
}
