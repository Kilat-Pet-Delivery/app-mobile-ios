import Foundation

protocol PaymentRepositoryProtocol {
    func initiate(request: InitiatePaymentRequest) async throws -> URL
}

final class PaymentRepository: PaymentRepositoryProtocol {
    private let authInterceptor: AuthInterceptor

    init(authInterceptor: AuthInterceptor) {
        self.authInterceptor = authInterceptor
    }

    convenience init(apiClient: APIClient = APIClient(), tokenStore: TokenStore = KeychainStore()) {
        self.init(authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore))
    }

    func initiate(request: InitiatePaymentRequest) async throws -> URL {
        let envelope: APIResponseEnvelope<InitiatePaymentResponse> = try await authInterceptor.perform(
            .initiatePayment,
            body: request
        )

        guard let url = envelope.data.redirectURL else {
            throw NetworkError.invalidResponse
        }

        return url
    }
}
