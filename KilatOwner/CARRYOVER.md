# KilatOwner — Backend-Reality Carryover Notes

> Derived from code that existed before the Phase A redesign reset.
> Every Phase B implementation tab should read this before writing a single line.
> Sources are the pre-deletion Swift files under `KilatOwner/` and the Go backend
> under `service-booking/internal/` and `service-payment/internal/`.

---

## 1. Booking State Machine

**Wire values** — confirmed from `service-booking/internal/domain/booking/booking_status.go` lines 8–15:

```
"requested"   StatusRequested
"accepted"    StatusAccepted
"in_progress" StatusInProgress
"delivered"   StatusDelivered
"completed"   StatusCompleted
"cancelled"   StatusCancelled
```

The backend state machine (`booking_status.go:18-25`) defines these transitions:

- `requested` → `accepted | cancelled`
- `accepted` → `in_progress | cancelled | requested` (re-queued on runner decline)
- `in_progress` → `delivered | cancelled`
- `delivered` → `completed`
- `completed` → (terminal)
- `cancelled` → (terminal)

**Critical divergence from spec assumption:** The spec rev-2 assumed cancel state was derived from a `cancelled_at` timestamp and that there were only four live states. The actual backend exposes both `"completed"` and `"cancelled"` as explicit string values. The iOS MVP's `BookingStatus` enum (`KilatOwner/Features/Jobs/BookingModels.swift:42-73`) only handled `requested / accepted / in_progress / delivered` and silently fell into `.unknown(String)` for `"completed"` and `"cancelled"`. The rewrite must add explicit cases for both.

**Design label mapping** — from `BookingModels.swift` comments and the spec:

| Wire value    | Design display label |
|---------------|----------------------|
| `requested`   | Pending              |
| `accepted`    | Confirmed            |
| `in_progress` | En route             |
| `delivered`   | Delivered            |
| `completed`   | Completed            |
| `cancelled`   | Cancelled            |

**lib-ui-ios StatusBadge** (v0.2.0) uses design-label enum cases
(`pending / confirmed / enroute / delivered / cancelled`). The mapping from wire
value to `StatusBadge` style lives in the app's domain `BookingStatus` extension,
NOT in the design system. `"completed"` maps to the same badge style as
`"delivered"` for display purposes (finality).

---

## 2. Payment as Separate Aggregate

Confirmed from `KilatOwner/Features/Payment/PaymentModels.swift` and
`KilatOwner/Features/Payment/PaymentRepository.swift`.

`Payment` is a distinct aggregate fetched independently:

```
GET /api/v1/payments/booking/:bookingId
```

(`APIEndpoint.swift:13`, `APIEndpoint.swift:61-62`: `"payments/booking/\(bookingId)"`)

`PaymentRepository.fetchByBooking` (`PaymentRepository.swift:50-59`) treats HTTP 404
as `nil` (not an error) because a booking exists before a payment is initiated.

**CTA derivation** — `BookingDetailViewModel.derivePrimaryAction` (`BookingDetailViewModel.swift:73-111`)
derives the primary action from the `(BookingDTO.status, PaymentDTO.escrowStatus)` tuple.
Booking and payment are fetched in parallel (`BookingDetailViewModel.swift:59-61`) on every
`refresh()` call.

**`escrow_status` enum wire values** — confirmed from `PaymentModels.swift:5-39`:

```
"pending"   PaymentEscrowStatus.pending
"held"      PaymentEscrowStatus.held
"released"  PaymentEscrowStatus.released
"refunded"  PaymentEscrowStatus.refunded
"failed"    PaymentEscrowStatus.failed
```

Note: the MVP added `.failed` beyond the four values in the spec. The backend
does emit `"failed"` on Stripe webhook failure. The rewrite must handle it.

**Full CTA truth table** (`BookingDetailViewModel.swift:73-111`):

| booking.status | payment.escrowStatus     | CTA               |
|----------------|--------------------------|-------------------|
| requested      | nil / pending / failed   | `.pay`            |
| requested      | held                     | `.waitingForRunner` |
| accepted       | held                     | `.waitingForPickup` |
| in_progress    | held                     | `.trackLive`      |
| delivered      | held / released          | `.completed`      |
| any            | refunded                 | `.refunded`       |
| anything else  | unexpected combo         | `.errorState`     |

---

## 3. Address Shape

Confirmed from `KilatOwner/Features/Booking/BookingCreateModels.swift:12-27` (outbound)
and `KilatOwner/Features/Jobs/BookingModels.swift:82-96` (inbound).

**Outbound `CreateBookingAddress`** (sent to server on booking create):

```swift
struct CreateBookingAddress: Encodable, Equatable {
    let line1: String
    let line2: String       // may be empty string — server tolerates it
    let city: String
    let state: String
    let postalCode: String
    let country: String
    let latitude: Double
    let longitude: Double
}
```

**Inbound `BookingAddress`** (received inside `BookingDTO`) — identical shape with an
added `singleLineLabel` computed var for UI display.

**PetShop = dropoff (not pickup).** The dropoff is pre-filled from the selected PetShop
record and passed as `dropoffPrefill` to `BookingCreateViewModel`
(`BookingCreateViewModel.swift:59`). The user never types the dropoff address.

**Pickup geocoding** — user types a free-text pickup address. The app calls
`CLGeocoder.geocodeAddressString(_:)` (no CoreLocation permission required — forward
geocoding from a string, not the device location). Implemented in `CLAddressGeocoder`
(`BookingCreateViewModel.swift:17-47`).

**Geocoder error handling** (`BookingCreateViewModel.swift:20-32`):

- `CLError.geocodeFoundNoResult` → `AddressGeocoderError.notFound` → UI: "Couldn't find
  that address — try a more specific one."
- Any other `CLError` → `AddressGeocoderError.transport` → UI: "Network error — try again
  in a moment."
- No result / nil coordinate in a valid response → `AddressGeocoderError.notFound`.

The `resolvedPickup` is validated non-nil before booking submission
(`BookingCreateViewModel.swift:154-156`). If missing, a field error is shown and
the network call is not made.

---

## 4. Pet Info Shape

Confirmed from `KilatOwner/Features/Booking/BookingCreateModels.swift:3-10` (outbound
`PetInfo`) and `service-booking/internal/domain/booking/pet_specification.go:7-14`
(backend `PetType` enum).

**Outbound `PetInfo`** (maps to server's `pet_spec` field in `CreateBookingRequest`):

```swift
struct PetInfo: Encodable, Equatable {
    let petType: String    // required — one of the enum values below
    let breed: String      // optional semantics — server accepts empty string
    let name: String       // required
    let weightKg: Double   // required, must be > 0
    let specialNeeds: String  // optional semantics — server accepts empty string
    let photoURL: String   // accepted by server; current MVP sends empty string
}
```

**`pet_type` enum wire values** — confirmed from both `BookingCreateViewModel.swift:87`
and `service-booking/internal/domain/booking/pet_specification.go:8-14`:

```
"cat" / "dog" / "bird" / "rabbit" / "reptile" / "other"
```

**`age_years` is not in this app's PetInfo.** The backend `PetSpecification` struct
(`pet_specification.go:52`) stores `age_months` (an `int`), but the MVP iOS app does
not send age at all — it sends an empty-string `breed` and `specialNeeds` if not
filled. The rewrite may add age, but note the wire field is `age_months` (integer),
not `age_years`.

**Required vs optional per backend validation** (`BookingCreateViewModel.swift:129-148`):
`petName`, `petType` (must be in enum), `weightKg > 0` are validated client-side.
`breed` and `specialNeeds` are optional; the MVP sends empty strings for both.

---

## 5. Pricing

**Server-computed. App never calculates or inputs a price.**

Confirmed from `KilatOwner/Features/Jobs/BookingModels.swift:14`:

```swift
let estimatedPriceCents: Int64
let finalPriceCents: Int64?     // nil until booking is completed
```

And the convenience accessor (`BookingModels.swift:77-79`):

```swift
var amountCents: Int64 {
    finalPriceCents ?? estimatedPriceCents
}
```

`estimatedPriceCents` is present from the moment the booking is created.
`finalPriceCents` is only set by the backend after delivery completion. The UI
always uses `amountCents` (the computed accessor) so it shows the final amount
once available and falls back to the estimate before that. The `PaymentInitiateView`
passes `booking.amountCents` to the payment initiation request
(`PaymentInitiateView.swift:33-38`). The user sees the price but has no input field
for it.

---

## 6. Stripe Redirect Flow

Confirmed from `PaymentRepository.swift`, `PaymentInitiateViewModel.swift`, and
`SafariCoordinator.swift`.

**Initiation:**

```
POST /api/v1/payments/initiate
Body: { booking_id, amount_cents, currency, customer_email }
```

(`APIEndpoint.swift:59`, `PaymentModels.swift:65-70`)

**Response shape** (`PaymentModels.swift:74-110`):

```swift
struct InitiatePaymentResponse: Decodable {
    let id: String?
    let bookingId: String?
    let amountCents: Int64?
    let currency: String?
    let escrowStatus: PaymentEscrowStatus?
    let redirectURL: URL?           // JSON key: "redirect_url"
    let paymentIntentId: String?    // tries "payment_intent_id" then "stripe_payment_id"
}
```

`redirect_url` is a Stripe Checkout URL. `paymentIntentId` falls back to
`stripePaymentId` if the primary key is absent (`PaymentModels.swift:101-103`).

**Browser step:** The app presents `SFSafariViewController` with `redirect_url`
(`PaymentInitiateView.swift:41-48`, `SafariCoordinator.swift`). `SFSafariViewControllerDelegate.safariViewControllerDidFinish` fires on both success and cancel — the app cannot distinguish them at this layer.

**Post-dismiss polling** (`PaymentInitiateViewModel.swift:55-71`,
`PaymentRepository.swift:62-75`):

- Endpoint: `GET /api/v1/payments/booking/:bookingId`
- Interval: **2 seconds**
- Max attempts: **15** (total timeout: ~30 seconds before giving up)
- Success condition: `payment.escrowStatus == .held`
- On timeout: `pollingState = .timedOut`; the UI instructs the user to pull-to-refresh.

There is no webhook callback or deep link — the app relies entirely on polling after
Safari dismiss.

---

## 7. Auth Profile Endpoint

Confirmed from `APIEndpoint.swift:52`:

```
GET /api/v1/auth/profile
```

(`APIEndpoint.path` for `.profile` case returns `"auth/profile"`;
`AppEnvironment.apiBaseURL` appends `"api/v1"` to the base URL.)

`AuthRepository.profile()` (`AuthRepository.swift:101-103`) wraps the call and returns a
`User` decoded from the envelope's `data` field. The endpoint requires a valid Bearer
token (`APIEndpoint.requiresAuth` is `true` for `.profile`).

The `User` response shape includes: `id, email, phone?, firstName?, lastName?, fullName?,
role, isVerified, avatarURL?, createdAt?` (`AuthModels.swift:25-71`).

---

## 8. API Response Envelope

Confirmed from `AuthInterceptor.swift:91-94`:

```swift
struct APIResponseEnvelope<Payload: Decodable>: Decodable {
    let data: Payload
    let success: Bool?
}
```

All successful responses are wrapped as `{ "success": true, "data": <payload> }`.
Pagination is not modelled in the generic envelope — endpoints that return paginated
lists (e.g. bookings list) embed pagination inside `data` or as a sibling key;
the MVP did not implement a paginated list view for the owner app so this was not
exercised.

**Error shape** — not modelled as a Decodable struct in the MVP. `NetworkError`
(`NetworkError.swift`) is derived entirely from the HTTP status code
(`APIClient.swift:93-108`):

- `401` → `NetworkError.unauthorized`
- `403` → `NetworkError.forbidden`
- `404` → `NetworkError.notFound`
- `5xx` → `NetworkError.serverError(Int)`
- Everything else non-2xx → `NetworkError.invalidResponse`

The `{ "success": false, "error": "...", "detail": "..." }` body is **not parsed** —
only the status code is used. The rewrite should parse the error body to show
meaningful server-side validation messages (e.g. duplicate email on register).

---

## 9. Logout Endpoint

Confirmed from `APIEndpoint.swift:49` and `AuthRepository.swift:106-112`:

```
POST /api/v1/auth/logout
```

The server call is best-effort. `AuthRepository.logout()` uses `try?` so network
failure, expired token, or offline state are all silently swallowed. Regardless of
server response, `tokenStore.clear()` is called unconditionally — this clears both
`accessToken` and `refreshToken` from Keychain (`KeychainStore.swift:40-43`).

The Keychain service identifier is `Bundle.main.bundleIdentifier ?? "my.kilat.KilatOwner"`
(`KeychainStore.swift:20`). Keys are `"accessToken"` and `"refreshToken"` as raw strings
from the `TokenKey` enum (`KeychainStore.swift:13-16`). Items are stored with
`kSecAttrAccessibleAfterFirstUnlock` accessibility so they survive a device restart
before the user unlocks (`KeychainStore.swift:54`).

---

## 10. WebSocket Tracking Topic

Confirmed from `TrackingRepository.swift:36-45` and `WebSocketClient.swift`.

**Subscribe URL shape:**

```
ws://<host>/ws/tracking/<bookingId>?token=<accessToken>
```

- Path: `/ws/tracking/{bookingId}` (not under `/api/v1/`; uses the raw base host)
- Auth: access token passed as `token` query parameter — NOT as a subprotocol or
  Authorization header. `URLSessionWebSocketTask` does not support custom headers
  at connection time in URLSession, so query-param is the only option without a
  custom transport.
- Base URL: `AppEnvironment.wsBaseURL` which swaps `http` → `ws` and `https` → `wss`
  from `AppEnvironment.baseURL` (`AppEnvironment.swift:14-19`).

(`TrackingRepository.subscribe` `TrackingRepository.swift:37-44`):

```swift
components?.path = "/ws/tracking/\(bookingId)"
components?.queryItems = [URLQueryItem(name: "token", value: token)]
```

**Message DTO structures** — the backend may emit either bare JSON or an envelope.
`TrackingRepository.decodeEvent` (`TrackingRepository.swift:62-84`) tries three decode
strategies in order:

1. Bare `LocationUpdate` / `TrackingUpdate` JSON:

```swift
struct TrackingUpdate: Decodable {
    let bookingId: String
    let runnerId: String
    let latitude: Double
    let longitude: Double
    let speedKmh: Double
    let headingDegrees: Double
    let timestamp: Date
}
```

2. Bare `BookingStatusEvent` JSON:

```swift
struct BookingStatusEvent: Decodable {
    let bookingId: String
    let oldStatus: BookingStatus?
    let newStatus: BookingStatus
    let timestamp: Date
}
```

3. Envelope with `type` discriminator (`TrackingRepository.swift:68-83`):

```swift
// { "type": "location"|"tracking.location"|"status"|"booking.status", "data": {...} }
```

The `SocketEnvelope.data` field is decoded as `AnyDecodable` then re-serialised to
`Data` before being decoded into the concrete type. Both `"location"` and
`"tracking.location"` are accepted as type strings, and both `"status"` and
`"booking.status"` are accepted. The rewrite should retain both aliases.

**Reconnect strategy** — `WebSocketClient` implements exponential backoff
(`WebSocketClient.swift:80-97`):

- Max reconnect attempts: **5** (configurable via `maxReconnectAttempts`)
- Backoff formula: `min(2^(attempt-1), 30)` seconds — so 1 s, 2 s, 4 s, 8 s, 16 s
- After 5 failed attempts: `state = .disconnected`; no further retry

**Fallback polling** — `LiveTrackingViewModel.startFallbackPolling` (`LiveTrackingViewModel.swift:90-98`)
runs a parallel polling loop at **5-second intervals** calling `GET /api/v1/bookings/:id`
regardless of WebSocket state. This updates `pickupCoord`, `dropoffCoord`, and `status`
even if the socket is down. The WS stream is the primary source; polling is the safety net.

**Delivery auto-dismiss** — when `BookingStatusEvent.newStatus == .delivered` or
`booking.status == .delivered` is polled, `LiveTrackingViewModel.completeAndDismiss()`
clears `appSession.activeBookingId` and sets `shouldDismiss = true`, which the view
observes to dismiss the sheet (`LiveTrackingView.swift:42-46`, `LiveTrackingViewModel.swift:129-132`).
