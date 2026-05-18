import Foundation

enum EscrowStatus: String, Codable, CaseIterable, Equatable, Sendable {
    case pending
    case held
    case released
    case refunded
    case failed
}

struct PaymentDTO: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let bookingID: UUID
    let ownerID: UUID
    let runnerID: UUID?
    let escrowStatus: EscrowStatus
    let amountCents: Int64
    let platformFeeCents: Int64
    let runnerPayoutCents: Int64
    let currency: String
    let paymentMethod: String
    let stripePaymentID: String
    let escrowHeldAt: Date?
    let escrowReleasedAt: Date?
    let refundedAt: Date?
    let refundReason: String
    let version: Int64
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case bookingID = "booking_id"
        case ownerID = "owner_id"
        case runnerID = "runner_id"
        case escrowStatus = "escrow_status"
        case amountCents = "amount_cents"
        case platformFeeCents = "platform_fee_cents"
        case runnerPayoutCents = "runner_payout_cents"
        case currency
        case paymentMethod = "payment_method"
        case stripePaymentID = "stripe_payment_id"
        case escrowHeldAt = "escrow_held_at"
        case escrowReleasedAt = "escrow_released_at"
        case refundedAt = "refunded_at"
        case refundReason = "refund_reason"
        case version
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct InitiatePaymentRequest: Codable, Equatable, Sendable {
    let bookingID: UUID
    let amountCents: Int64
    let currency: String
    let customerEmail: String

    enum CodingKeys: String, CodingKey {
        case bookingID = "booking_id"
        case amountCents = "amount_cents"
        case currency
        case customerEmail = "customer_email"
    }
}

struct InitiatePaymentResponse: Codable, Equatable, Sendable {
    let id: UUID?
    let bookingID: UUID?
    let amountCents: Int64?
    let currency: String?
    let escrowStatus: EscrowStatus?
    let redirectURL: URL?
    let paymentIntentID: String?

    enum CodingKeys: String, CodingKey {
        case id
        case bookingID = "booking_id"
        case amountCents = "amount_cents"
        case currency
        case escrowStatus = "escrow_status"
        case redirectURL = "redirect_url"
        case paymentIntentID = "payment_intent_id"
        case stripePaymentID = "stripe_payment_id"
    }

    init(
        id: UUID?,
        bookingID: UUID?,
        amountCents: Int64?,
        currency: String?,
        escrowStatus: EscrowStatus?,
        redirectURL: URL?,
        paymentIntentID: String?
    ) {
        self.id = id
        self.bookingID = bookingID
        self.amountCents = amountCents
        self.currency = currency
        self.escrowStatus = escrowStatus
        self.redirectURL = redirectURL
        self.paymentIntentID = paymentIntentID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id)
        bookingID = try container.decodeIfPresent(UUID.self, forKey: .bookingID)
        amountCents = try container.decodeIfPresent(Int64.self, forKey: .amountCents)
        currency = try container.decodeIfPresent(String.self, forKey: .currency)
        escrowStatus = try container.decodeIfPresent(EscrowStatus.self, forKey: .escrowStatus)
        redirectURL = try container.decodeIfPresent(URL.self, forKey: .redirectURL)
        paymentIntentID = try container.decodeIfPresent(String.self, forKey: .paymentIntentID)
            ?? container.decodeIfPresent(String.self, forKey: .stripePaymentID)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(bookingID, forKey: .bookingID)
        try container.encodeIfPresent(amountCents, forKey: .amountCents)
        try container.encodeIfPresent(currency, forKey: .currency)
        try container.encodeIfPresent(escrowStatus, forKey: .escrowStatus)
        try container.encodeIfPresent(redirectURL, forKey: .redirectURL)
        try container.encodeIfPresent(paymentIntentID, forKey: .paymentIntentID)
    }
}
