# Kilat Owner iOS

Native iOS MVP for the Kilat pet-owner happy path: register, login, browse pet shops, create a booking, initiate payment, track delivery progress, and confirm completion.

## Stack

- Swift 5.9+
- SwiftUI with Observation
- URLSession and URLSessionWebSocketTask
- MapKit
- SafariServices
- Keychain
- XCTest

## Local Development

1. Open `KilatOwner.xcodeproj` in Xcode 15 or newer.
2. Select an iOS 17+ simulator.
3. Run the `KilatOwner` scheme.
4. Start the backend gateway at `http://localhost:8080` before using live API flows.

Debug builds target `http://localhost:8080/api/v1` and `ws://localhost:8080`.

## Documents

- Spec: `../docs/superpowers/specs/2026-05-16-app-mobile-ios-mvp-design.md`
- Plan: `../docs/superpowers/plans/2026-05-16-app-mobile-ios-mvp-plan.md`
