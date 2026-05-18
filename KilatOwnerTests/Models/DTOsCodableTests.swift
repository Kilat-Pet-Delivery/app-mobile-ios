import XCTest
@testable import KilatOwner

final class DTOsCodableTests: XCTestCase {
    private let decoder = DTOTestFactory.makeDecoder()
    private let encoder = DTOTestFactory.makeEncoder()

    func testLoginRequest_JSONRoundTrip() throws {
        let json = #"{"email":"mei.ling@example.com","password":"password123"}"#

        try assertRoundTrip(LoginRequest.self, json: json)
    }

    func testRegisterRequest_JSONRoundTrip() throws {
        let json = #"{"email":"mei.ling@example.com","phone":"+60123456789","full_name":"Mei Ling Chen","password":"password123","role":"owner"}"#

        try assertRoundTrip(RegisterRequest.self, json: json)
    }

    func testRegisterRequest_withFirstPet_JSONRoundTrip() throws {
        let json = """
        {
          "email": "mei.ling@example.com",
          "phone": "+60123456789",
          "full_name": "Mei Ling Chen",
          "password": "password123",
          "role": "owner",
          "first_pet": {
            "pet_type": "cat",
            "name": "Mochi",
            "weight_kg": 4.2
          }
        }
        """

        try assertRoundTrip(RegisterRequest.self, json: json)
    }

    func testLoginResponse_JSONRoundTrip() throws {
        let json = """
        {
          "access_token": "access-token",
          "refresh_token": "refresh-token",
          "user": \(DTOTestFactory.profileJSON)
        }
        """

        try assertRoundTrip(LoginResponse.self, json: json)
    }

    func testProfileDTO_JSONRoundTrip() throws {
        try assertRoundTrip(ProfileDTO.self, json: DTOTestFactory.profileJSON)
    }

    func testForgotPasswordRequest_JSONRoundTrip() throws {
        let json = #"{"email":"mei.ling@example.com"}"#

        try assertRoundTrip(ForgotPasswordRequest.self, json: json)
    }

    func testResetPasswordRequest_JSONRoundTrip() throws {
        let json = #"{"token":"reset-token","newPassword":"newPassword123"}"#

        try assertRoundTrip(ResetPasswordRequest.self, json: json)
    }

    func testAddressDTO_JSONRoundTrip() throws {
        try assertRoundTrip(AddressDTO.self, json: DTOTestFactory.addressJSON(line1: "12 Jalan Ampang"))
    }

    func testPetSpecDTO_JSONRoundTrip() throws {
        try assertRoundTrip(PetSpecDTO.self, json: DTOTestFactory.petJSON)
    }

    func testCreateBookingRequest_JSONRoundTrip() throws {
        let json = """
        {
          "pet_spec": \(DTOTestFactory.petJSON),
          "pickup_address": \(DTOTestFactory.addressJSON(line1: "12 Jalan Ampang")),
          "dropoff_address": \(DTOTestFactory.addressJSON(line1: "Kilat Vet Clinic")),
          "scheduled_at": "2026-05-18T04:30:00Z",
          "notes": "Mochi gets nervous around traffic"
        }
        """

        try assertRoundTrip(CreateBookingRequest.self, json: json)
    }

    func testBookingDTO_JSONRoundTrip() throws {
        try assertRoundTrip(BookingDTO.self, json: DTOTestFactory.bookingJSON)
    }

    func testCancelBookingRequest_JSONRoundTrip() throws {
        let json = #"{"reason":"changed_mind"}"#

        try assertRoundTrip(CancelBookingRequest.self, json: json)
    }

    func testPaymentDTO_JSONRoundTrip() throws {
        try assertRoundTrip(PaymentDTO.self, json: DTOTestFactory.paymentJSON)
    }

    func testInitiatePaymentRequest_JSONRoundTrip() throws {
        let json = #"{"booking_id":"11111111-1111-1111-1111-111111111111","amount_cents":1800,"currency":"MYR","customer_email":"mei.ling@example.com"}"#

        try assertRoundTrip(InitiatePaymentRequest.self, json: json)
    }

    func testInitiatePaymentResponse_JSONRoundTrip() throws {
        let json = """
        {
          "id": "22222222-2222-2222-2222-222222222222",
          "booking_id": "11111111-1111-1111-1111-111111111111",
          "amount_cents": 1800,
          "currency": "MYR",
          "escrow_status": "pending",
          "redirect_url": "https://checkout.stripe.test/pay/cs_test",
          "payment_intent_id": "pi_test_123"
        }
        """

        try assertRoundTrip(InitiatePaymentResponse.self, json: json)
    }

    func testNotificationDTO_JSONRoundTrip() throws {
        let json = #"{"id":"notif_1","type":"booking.accepted","title":"Runner assigned","body":"Aiman is on the way","created_at":"2026-05-18T04:35:00Z","read_at":null}"#

        try assertRoundTrip(NotificationDTO.self, json: json)
    }

    private func assertRoundTrip<T: Codable & Equatable>(
        _ type: T.Type,
        json: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let data = try XCTUnwrap(json.data(using: .utf8), file: file, line: line)
        let decoded = try decoder.decode(T.self, from: data)
        let encoded = try encoder.encode(decoded)
        let redecode = try decoder.decode(T.self, from: encoded)
        XCTAssertEqual(decoded, redecode, file: file, line: line)
    }
}

private enum DTOTestFactory {
    static let profileJSON = #"{"id":"00000000-0000-0000-0000-000000000001","email":"mei.ling@example.com","phone":"+60123456789","full_name":"Mei Ling Chen","role":"owner","is_verified":true,"avatar_url":"https://cdn.kilat.test/mei.png","created_at":"2026-05-18T03:00:00Z"}"#

    static let petJSON = #"{"pet_type":"cat","breed":"Calico","name":"Mochi","weight_kg":4.2,"age_months":36,"vaccinations":[{"vaccine_name":"Rabies","date_given":"2025-11-01T00:00:00Z","expires_at":"2026-11-01T00:00:00Z","vet_name":"Kilat Vet","verified":true}],"special_needs":"Keep carrier covered","photo_url":"https://cdn.kilat.test/mochi.png"}"#

    static let bookingJSON = """
    {
      "id": "11111111-1111-1111-1111-111111111111",
      "booking_number": "KLT-2026-0001",
      "owner_id": "00000000-0000-0000-0000-000000000001",
      "runner_id": "00000000-0000-0000-0000-000000000002",
      "status": "in_progress",
      "pet_spec": \(petJSON),
      "crate_requirement": {
        "minimum_size": "small",
        "needs_ventilation": true,
        "needs_temp_control": false,
        "minimum_weight_capacity": 5.04
      },
      "pickup_address": \(addressJSON(line1: "12 Jalan Ampang")),
      "dropoff_address": \(addressJSON(line1: "Kilat Vet Clinic")),
      "route_spec": {
        "pickup_lat": 3.1599,
        "pickup_lng": 101.7123,
        "dropoff_lat": 3.1478,
        "dropoff_lng": 101.6953,
        "distance_km": 4.8,
        "estimated_duration_min": 18,
        "polyline": "abc123"
      },
      "estimated_price_cents": 1800,
      "final_price_cents": null,
      "currency": "MYR",
      "scheduled_at": "2026-05-18T04:30:00Z",
      "picked_up_at": "2026-05-18T04:45:00Z",
      "delivered_at": null,
      "cancelled_at": null,
      "cancel_note": "",
      "notes": "Mochi gets nervous around traffic",
      "version": 2,
      "created_at": "2026-05-18T04:00:00Z",
      "updated_at": "2026-05-18T04:45:00Z"
    }
    """

    static let paymentJSON = """
    {
      "id": "22222222-2222-2222-2222-222222222222",
      "booking_id": "11111111-1111-1111-1111-111111111111",
      "owner_id": "00000000-0000-0000-0000-000000000001",
      "runner_id": "00000000-0000-0000-0000-000000000002",
      "escrow_status": "held",
      "amount_cents": 1800,
      "platform_fee_cents": 360,
      "runner_payout_cents": 1440,
      "currency": "MYR",
      "payment_method": "stripe",
      "stripe_payment_id": "pi_test_123",
      "escrow_held_at": "2026-05-18T04:40:00Z",
      "escrow_released_at": null,
      "refunded_at": null,
      "refund_reason": "",
      "version": 1,
      "created_at": "2026-05-18T04:39:00Z",
      "updated_at": "2026-05-18T04:40:00Z"
    }
    """

    static func addressJSON(line1: String) -> String {
        #"{"line1":"\#(line1)","line2":"","city":"Kuala Lumpur","state":"WP Kuala Lumpur","postal_code":"50450","country":"MY","latitude":3.1599,"longitude":101.7123}"#
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}
