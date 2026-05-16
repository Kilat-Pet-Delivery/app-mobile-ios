# Kilat Owner iOS Manual Smoke Checklist

Use this checklist for the real-device MVP smoke. Run it on a physical iPhone with the backend gateway reachable from the device.

## Setup

- [ ] Backend stack is running from `../infrastructure`.
- [ ] Gateway health passes at `/health`.
- [ ] `KilatOwner/App/AppEnvironment.swift` points to the reachable backend host.
- [ ] Xcode scheme is `KilatOwner`, Debug configuration.
- [ ] Login stub remains off by default. `KILAT_LOGIN_STUB` is only used when deliberately added as a launch environment variable.
- [ ] A runner account is available to accept and stream the delivery.

## Happy Path

- [ ] Clean install opens Splash, then routes to Login with no saved token.
- [ ] Register creates a customer account and lands on Home.
- [ ] Logout returns to Login.
- [ ] Login with the same account lands on Home.
- [ ] Browse Pet Shops opens the list and returns real pet shops.
- [ ] Search/filter does not crash and keeps the list usable.
- [ ] Pet shop detail loads services and contact details.
- [ ] Book Delivery opens the booking form with the selected shop id.
- [ ] Empty booking submit shows inline validation.
- [ ] Valid booking submit creates a booking and sets it as active.
- [ ] Booking Detail shows status, pet, addresses, schedule, and amount.
- [ ] Pay Now opens the payment sheet/Safari flow.
- [ ] Dismissing Safari polls the booking and refreshes status.
- [ ] Runner accepts/picks up the booking from the runner app.
- [ ] Track Live opens the map with pickup/dropoff pins.
- [ ] Runner location updates move the runner pin and draw a route trail.
- [ ] Delivered/completed status clears the active booking and dismisses tracking.
- [ ] Relaunch preserves auth and routes correctly from Splash.

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
| Booking create/detail | Not run | |
| Payment flow | Not run | |
| Live tracking | Not run | |
| Delivery completion | Not run | |
| Relaunch auth | Not run | |

## Follow-Ups

- Real-device smoke not run in this coding pass.
- Compile/tests intentionally not run per request.
