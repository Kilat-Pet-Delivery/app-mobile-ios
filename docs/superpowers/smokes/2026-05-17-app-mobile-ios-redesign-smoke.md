# App Mobile iOS Redesign Smoke Pass

Date: 2026-05-18
Task: C.4 smoke pass - simulator, real device, dark mode
Starting commit: `c228863`
Tester: Codex

## Environment

- App repo: `app-mobile-ios`
- Simulator: iPhone 17, iOS 26.5, UDID `B36E20E9-2CC9-4396-8F7E-3E27E6853D4F`
- Stub scheme: `KilatOwner Stub Mode`
- Bundle ID: `my.kilat.KilatOwner`
- Backend target: `https://api.kilat.local`
- Backend status: blocked. `curl -I --max-time 5 https://api.kilat.local` timed out during DNS resolution.
- Physical device status: blocked. `xcrun xctrace list devices` showed the Mac and simulators only; no physical iPhone was attached.

## Simulator Smoke

- [x] Built `KilatOwner Stub Mode` for iPhone 17 simulator.
- [x] Clean-installed the app into the simulator.
- [x] Launched with `SIMCTL_CHILD_KILAT_OWNER_STUB=1`.
- [x] Verified splash/auth gate resolves directly into the stub Home persona.
- [x] Verified Home renders with visible header, active booking, pets, services, and recent trips sections.
- [x] Verified active booking footer exposes both chat and track actions on iPhone 17 width.
- [x] Switched simulator to dark mode and relaunched.
- [x] Verified dark-mode Home has readable contrast and no obvious clipping.

Screenshots captured locally:

- `/tmp/kilat-owner-smoke/screenshots/stub-home-light-footer-responsive.png`
- `/tmp/kilat-owner-smoke/screenshots/stub-home-dark-footer-responsive.png`

## Golden Path Against Backend

- [ ] Fresh launch -> Splash -> Login: blocked by backend DNS.
- [ ] Signup with new account and pet: blocked by backend DNS.
- [ ] Book first run through service selection and booking detail: blocked by backend DNS.
- [ ] Stripe checkout through Safari sheet: blocked by backend DNS.
- [ ] Escrow held -> BookingConfirmed: blocked by backend DNS.
- [ ] Runner assignment and live tracking with runner simulator: blocked by backend DNS.
- [ ] Notifications inbox status-change events: blocked by backend DNS.
- [ ] Cancel booking from detail: blocked by backend DNS.
- [ ] Logout from Home menu: blocked by backend DNS for real auth flow.

## Edge Cases

- [ ] Forgot password recovery email and link: blocked by backend DNS and email access.
- [ ] Fresh-account empty state: blocked by backend DNS; covered only by existing Home snapshot test in this pass.
- [x] Dark mode Home in stub mode.
- [ ] Push lock-screen preview manual pass: not reached in this smoke window.

## Issues Found And Fixed Inline

1. Initial auth route was pushed onto the navigation stack instead of becoming the app root. This produced a phantom back button and left the placeholder/debug root underneath Home.
   - Fix: added `RootCoordinator.rootRoute` plus `setRoot(_:)`, used it from `AuthGate`, and rendered `rootRoute` directly from `RootView`.

2. Stub Home content clipped horizontally on iPhone 17 because the fixed max-width frame resolved wider than the phone inside the vertical `ScrollView`.
   - Fix: constrained Home content with the local `GeometryReader` width and kept it centered in the scroll view.

3. The active booking footer clipped the track button on iPhone 17.
   - Fix: made the footer responsive with `ViewThatFits`, preserving the single-row layout where it fits and using a compact two-row fallback on narrow widths.

## Rechecks

- [x] Rebuilt and relaunched stub mode after fixes.
- [x] Rechecked light mode screenshot after fixes.
- [x] Rechecked dark mode screenshot after fixes.
- [x] Regenerated and passed Home snapshot baselines after the layout change.
- [x] Passed focused AuthGate, RootCoordinator, and Home snapshot tests.

## Follow-Ups

- Real-backend golden path still needs a pass once `api.kilat.local` resolves from the test machine.
- Real-device pass still needs a pass with Luqman's iPhone attached.
