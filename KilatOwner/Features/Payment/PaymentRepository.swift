import Foundation

protocol PaymentRepositoryProtocol {
    func initiate(request: InitiatePaymentRequest) async throws -> InitiatePaymentResponse
    func fetchByBooking(bookingId: String) async throws -> Payment?
    func pollEscrow(
        bookingId: String,
        intervalSeconds: Double,
        maxAttempts: Int,
        until: @escaping (Payment) -> Bool
    ) async throws -> Payment?
}

extension PaymentRepositoryProtocol {
    // Default for tests that don't need polling.
    func pollEscrow(
        bookingId: String,
        intervalSeconds: Double = 2,
        maxAttempts: Int = 15,
        until: @escaping (Payment) -> Bool
    ) async throws -> Payment? {
        try await pollEscrow(
            bookingId: bookingId,
            intervalSeconds: intervalSeconds,
            maxAttempts: maxAttempts,
            until: until
        )
    }
}

final class PaymentRepository: PaymentRepositoryProtocol {
    private let authInterceptor: AuthInterceptor

    init(authInterceptor: AuthInterceptor) {
        self.authInterceptor = authInterceptor
    }

    convenience init(apiClient: APIClient = APIClient(), tokenStore: TokenStore = KeychainStore()) {
        self.init(authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore))
    }

    func initiate(request: InitiatePaymentRequest) async throws -> InitiatePaymentResponse {
        let envelope: APIResponseEnvelope<InitiatePaymentResponse> = try await authInterceptor.perform(
            .initiatePayment,
            body: request
        )
        return envelope.data
    }

    func fetchByBooking(bookingId: String) async throws -> Payment? {
        do {
            let envelope: APIResponseEnvelope<Payment> = try await authInterceptor.perform(
                .paymentByBooking(bookingId: bookingId)
            )
            return envelope.data
        } catch NetworkError.notFound {
            // Booking exists but payment not yet initiated — treat as nil, not error.
            return nil
        }
    }

    func pollEscrow(
        bookingId: String,
        intervalSeconds: Double,
        maxAttempts: Int,
        until: @escaping (Payment) -> Bool
    ) async throws -> Payment? {
        for _ in 0..<maxAttempts {
            if let payment = try await fetchByBooking(bookingId: bookingId), until(payment) {
                return payment
            }
            try await Task.sleep(for: .seconds(intervalSeconds))
        }
        return nil
    }
}
