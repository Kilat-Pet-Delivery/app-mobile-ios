import Foundation

struct PaymentRepositoryImpl: PaymentRepository {
    typealias Sleeper = (UInt64) async throws -> Void

    private let client: APIClient
    private let pollIntervalNanoseconds: UInt64
    private let timeoutNanoseconds: UInt64
    private let sleep: Sleeper

    init(
        client: APIClient,
        pollIntervalNanoseconds: UInt64 = 2_000_000_000,
        timeoutNanoseconds: UInt64 = 60_000_000_000,
        sleep: @escaping Sleeper = { try await Task.sleep(nanoseconds: $0) }
    ) {
        self.client = client
        self.pollIntervalNanoseconds = pollIntervalNanoseconds
        self.timeoutNanoseconds = timeoutNanoseconds
        self.sleep = sleep
    }

    func initiate(
        bookingID: String,
        amountCents: Int64,
        currency: String,
        customerEmail: String
    ) async throws -> InitiatePaymentResponse {
        guard let bookingUUID = UUID(uuidString: bookingID) else {
            throw APIError.invalidURL
        }

        let request = InitiatePaymentRequest(
            bookingID: bookingUUID,
            amountCents: amountCents,
            currency: currency,
            customerEmail: customerEmail
        )
        return try await client.post(Endpoints.Payment.initiate, body: request)
    }

    func pollEscrow(bookingID: String) async throws -> PaymentDTO {
        let attempts = max(1, Int(ceil(Double(timeoutNanoseconds) / Double(max(1, pollIntervalNanoseconds)))))

        for attempt in 0..<attempts {
            let payment: PaymentDTO = try await client.get(Endpoints.Payment.byBooking(bookingID: bookingID))
            if payment.escrowStatus == .held {
                return payment
            }

            if attempt < attempts - 1 {
                try await sleep(pollIntervalNanoseconds)
            }
        }

        throw APIError.timeout(message: "Payment escrow polling timed out.")
    }
}
