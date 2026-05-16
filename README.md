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

## Running on Device

`localhost` only works in the simulator. For a physical iPhone, update `KilatOwner/App/AppEnvironment.swift` in Debug to use the backend host's LAN IP, for example `http://192.168.1.20:8080`. Keep the matching WebSocket host reachable on the same network.

The development login shortcut is gated behind the `KILAT_LOGIN_STUB` launch environment variable and is off by default.

## Documents

- Spec: `../docs/superpowers/specs/2026-05-16-app-mobile-ios-mvp-design.md`
- Plan: `../docs/superpowers/plans/2026-05-16-app-mobile-ios-mvp-plan.md`
