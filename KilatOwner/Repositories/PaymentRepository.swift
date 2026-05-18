import Foundation

protocol PaymentRepository {
    func initiate(
        bookingID: String,
        amountCents: Int64,
        currency: String,
        customerEmail: String
    ) async throws -> InitiatePaymentResponse

    func pollEscrow(bookingID: String) async throws -> PaymentDTO
}
