import Foundation

// Matches service-payment domain. Backend may add states; `.unknown` keeps decode
// safe so the app doesn't crash when that happens — UI falls back to a neutral state.
enum PaymentEscrowStatus: Decodable, Equatable {
    case pending
    case held
    case released
    case refunded
    case failed
    case unknown(String)

    init(rawValue: String) {
        switch rawValue {
        case "pending": self = .pending
        case "held": self = .held
        case "released": self = .released
        case "refunded": self = .refunded
        case "failed": self = .failed
        default: self = .unknown(rawValue)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = .init(rawValue: raw)
    }

    var rawValue: String {
        switch self {
        case .pending: return "pending"
        case .held: return "held"
        case .released: return "released"
        case .refunded: return "refunded"
        case .failed: return "failed"
        case .unknown(let raw): return raw
        }
    }
}

// Mirrors PaymentDTO in service-payment/internal/application/payment_service.go.
// Optional fields use ?? defaults in init to tolerate partial server payloads.
struct Payment: Decodable, Equatable, Identifiable {
    let id: String
    let bookingId: String
    let ownerId: String
    let runnerId: String?
    let escrowStatus: PaymentEscrowStatus
    let amountCents: Int64
    let platformFeeCents: Int64
    let runnerPayoutCents: Int64
    let currency: String
    let paymentMethod: String?
    let stripePaymentId: String?
    let escrowHeldAt: Date?
    let escrowReleasedAt: Date?
    let refundedAt: Date?
    let refundReason: String?
    let version: Int64
    let createdAt: Date
    let updatedAt: Date
}

struct InitiatePaymentRequest: Encodable, Equatable {
    let bookingId: String
    let amountCents: Int64
    let currency: String
    let customerEmail: String
}

// Backend returns the freshly-created Payment record on initiate.
// `redirect_url` is added by the Stripe Checkout integration on top of the PaymentDTO shape.
struct InitiatePaymentResponse: Decodable, Equatable {
    let id: String?
    let bookingId: String?
    let amountCents: Int64?
    let currency: String?
    let escrowStatus: PaymentEscrowStatus?
    let redirectURL: URL?
    let paymentIntentId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case bookingId
        case amountCents
        case currency
        case escrowStatus
        case redirectURL = "redirect_url"
        case paymentIntentId
        case stripePaymentId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        bookingId = try container.decodeIfPresent(String.self, forKey: .bookingId)
        amountCents = try container.decodeIfPresent(Int64.self, forKey: .amountCents)
        currency = try container.decodeIfPresent(String.self, forKey: .currency)
        escrowStatus = try container.decodeIfPresent(PaymentEscrowStatus.self, forKey: .escrowStatus)
        paymentIntentId = try container.decodeIfPresent(String.self, forKey: .paymentIntentId)
            ?? container.decodeIfPresent(String.self, forKey: .stripePaymentId)

        if let rawRedirect = try container.decodeIfPresent(String.self, forKey: .redirectURL) {
            redirectURL = URL(string: rawRedirect)
        } else {
            redirectURL = nil
        }
    }
}
