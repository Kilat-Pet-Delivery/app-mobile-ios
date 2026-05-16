# Kilat Owner iOS Manual Smoke Checklist

Use this checklist for the real-device MVP smoke. Run it on a physical iPhone with the backend gateway reachable from the device.

Aligned with spec rev-2 (2026-05-16) — pet shop = dropoff, payment is a separate aggregate, Stripe Checkout via Safari.

## Setup

- [ ] Backend stack is running from `../infrastructure` (no port conflicts with other local stacks).
- [ ] Gateway health passes at `/health`.
- [ ] Stripe test mode is configured in `service-payment` (test card `4242 4242 4242 4242` accepted).
- [ ] `KilatOwner/App/AppEnvironment.swift` points to the reachable backend host.
- [ ] Xcode scheme is `KilatOwner`, Debug configuration.
- [ ] Login stub remains off by default. `KILAT_LOGIN_STUB` is only set as a launch env var when deliberately exercising the stub path.
- [ ] A runner account is available on another device or via Bruno to accept and stream the delivery.

## Happy Path

### Auth + entry

- [ ] Clean install opens Splash, then routes to Login with no saved token.
- [ ] Register creates a customer account; lands on Home.
- [ ] Logout from Home menu returns to Login (server-side `/auth/logout` revoke + local Keychain clear).
- [ ] Login with the same account lands on Home.
- [ ] Relaunch preserves auth and routes from Splash directly to Home via `/auth/profile`.

### Browse + booking create

- [ ] Browse Pet Shops opens the list and returns real pet shops.
- [ ] Search filters the list locally without crashing.
- [ ] Pet shop detail loads services and contact details.
- [ ] "Book Delivery Here" opens BookingCreate with the shop locked as the **dropoff** (read-only card at top).
- [ ] Typing a real KL pickup address and tapping Verify resolves it via CLGeocoder; a green check + resolved address appears.
- [ ] Typing nonsense ("asdfgh") and Verify surfaces the "Couldn't find that address" inline error.
- [ ] Submit is disabled until pickup is verified, pet name is set, weight is a positive number.
- [ ] Valid submit creates the booking and routes to BookingDetail; `AppSession.activeBookingId` is now set.

### Booking detail + payment

- [ ] BookingDetail shows status `requested`, pet info, both addresses, scheduled time (if any), and `estimated_price_cents` formatted as `MYR x.xx`.
- [ ] Primary CTA shows **Pay Now** (since payment is nil immediately after booking creation).
- [ ] Tap Pay Now → sheet opens → Safari opens with the Stripe Checkout URL.
- [ ] Completing the sandbox Stripe payment (card `4242 4242 4242 4242`, any future expiry, any CVC) and tapping Done returns to the app.
- [ ] App polls `GET /payments/booking/:id` and surfaces the escrow transition to `held`; BookingDetail refreshes.
- [ ] Primary CTA flips to **Waiting for a runner to accept** (no action).

### Runner acceptance + tracking

- [ ] On another device or via Bruno, accept the booking (`POST /bookings/:id/accept`). Booking status moves to `accepted`.
- [ ] BookingDetail pull-to-refresh shows CTA **Runner on the way to pick up your pet**.
- [ ] Mark pickup runs the booking to `in_progress`.
- [ ] BookingDetail refresh shows CTA **Track Live**.
- [ ] Tap Track Live → MapKit renders pickup pin, dropoff pin, and the runner annotation.
- [ ] Runner streams GPS via WS → runner pin moves and a polyline trail grows.
- [ ] If WebSocket disconnects, the reconnecting state is visible and the parallel 5s booking poll continues to update status.

### Delivery completion

- [ ] Runner marks delivered → booking status moves to `delivered`.
- [ ] LiveTracking auto-dismisses after the Delivered overlay.
- [ ] `AppSession.activeBookingId` clears.
- [ ] Home shows no active booking card.

## Result Log

Date:
Device:
iOS version:
Backend commit(s):
App commit:

| Item | Result | Notes |
| --- | --- | --- |
| Clean install routing | Not run | |
| Register | Not run | |
| Logout/Login | Not run | |
| Pet shop list/detail | Not run | |
| Booking create with CLGeocoder pickup | Not run | |
| Payment (Stripe sandbox) — escrow transitions to held | Not run | |
| Runner acceptance → status transitions | Not run | |
| Live tracking — runner movement | Not run | |
| Delivery completion + active-booking clear | Not run | |
| Relaunch auth | Not run | |

## Known Follow-Ups

- Phase 0 Task 0.3 (curl-verify all endpoints + capture fixtures into `dev-fixtures.md`) is **deferred** until Kilat backend can run alongside Niaga or replace it on ports 8080/4222/5433/6379. Run it before the first smoke.
- Xcode .pbxproj cleanup pass: move `AddressGeocoder` out of `BookingCreateViewModel.swift` into its own `Core/Geocoding/` file; move `PaginatedAPIResponseEnvelope` out of `Features/Earnings/EarningsModels.swift` into `Core/Network/`; delete runner-iOS leftover dirs (`Features/ActiveDelivery`, `Features/Dashboard`, `Features/Earnings`, `Features/Jobs` after migrating `BookingModels.swift` to `Features/Booking/`, `Core/Location`).
- `BookingRepository` retains runner-iOS legacy methods (`listAvailable`, `accept`, `markPickup`, `markDelivered`) — unused by owner code, kept compiling pending the cleanup pass.
- Real-device smoke not run in this coding pass.
