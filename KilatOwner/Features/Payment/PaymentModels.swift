import Foundation

struct InitiatePaymentRequest: Encodable, Equatable {
    let bookingId: String
    let amountCents: Int64
    let currency: String
    let customerEmail: String
}

struct InitiatePaymentResponse: Decodable, Equatable {
    let id: String?
    let bookingId: String?
    let amountCents: Int64?
    let currency: String?
    let escrowStatus: String?
    let redirectURL: URL?
    let paymentIntentId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case bookingId
        case amountCents
        case currency
        case escrowStatus
        case redirectURL
        case paymentIntentId
        case stripePaymentId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        bookingId = try container.decodeIfPresent(String.self, forKey: .bookingId)
        amountCents = try container.decodeIfPresent(Int64.self, forKey: .amountCents)
        currency = try container.decodeIfPresent(String.self, forKey: .currency)
        escrowStatus = try container.decodeIfPresent(String.self, forKey: .escrowStatus)
        paymentIntentId = try container.decodeIfPresent(String.self, forKey: .paymentIntentId)
            ?? container.decodeIfPresent(String.self, forKey: .stripePaymentId)

        if let rawRedirect = try container.decodeIfPresent(String.self, forKey: .redirectURL) {
            redirectURL = URL(string: rawRedirect)
        } else if let id = try container.decodeIfPresent(String.self, forKey: .id) {
            redirectURL = URL(string: "https://kilat.my/payments/\(id)")
        } else {
            redirectURL = nil
        }
    }
}
