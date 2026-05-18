import SafariServices
import SwiftUI
import XCTest
@testable import KilatOwner

@MainActor
final class PaymentSafariSheetTests: XCTestCase {
    func testPaymentSafariSheet_dismissCallback_firesWhenSheetDismissed() {
        let url = URL(string: "https://checkout.stripe.com/c/pay/cs_test_123")!
        var dismissCount = 0
        let sheet = PaymentSafariSheet(redirectURL: url) {
            dismissCount += 1
        }

        let coordinator = sheet.makeCoordinator()
        coordinator.safariViewControllerDidFinish(SFSafariViewController(url: url))

        XCTAssertEqual(dismissCount, 1)
    }

    func testPaymentSafariSheet_wrapsSFSafariViewController() {
        let url = URL(string: "https://checkout.stripe.com/c/pay/cs_test_123")!
        let sheet = PaymentSafariSheet(redirectURL: url) {}

        assertSafariRepresentable(sheet)
    }

    private func assertSafariRepresentable<T: UIViewControllerRepresentable>(_ view: T) where T.UIViewControllerType == SFSafariViewController {}
}
