import Foundation
import Observation

@MainActor
@Observable
final class CancelReasonViewModel {
    let bookingID: String
    let reasons: [CancelReason]

    var selectedReason: CancelReason?
    var freeText: String
    var isSubmitting: Bool
    var errorMessage: String?

    private let bookingRepository: BookingRepository
    private let onCancelled: (BookingDTO) -> Void

    init(
        bookingID: String,
        bookingRepository: BookingRepository,
        selectedReason: CancelReason? = nil,
        freeText: String = "",
        onCancelled: @escaping (BookingDTO) -> Void = { _ in }
    ) {
        self.bookingID = bookingID
        self.bookingRepository = bookingRepository
        self.selectedReason = selectedReason
        self.freeText = freeText
        self.onCancelled = onCancelled
        self.reasons = CancelReason.allCases
        self.isSubmitting = false
    }

    var isSubmitEnabled: Bool {
        selectedReason != nil && !isSubmitting
    }

    var showsFreeTextField: Bool {
        selectedReason == .other
    }

    func selectReason(_ reason: CancelReason) {
        selectedReason = reason
        errorMessage = nil

        if reason != .other {
            freeText = ""
        }
    }

    func submit() async {
        guard let selectedReason, isSubmitEnabled else { return }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let cancelledBooking = try await bookingRepository.cancel(
                id: bookingID,
                reason: selectedReason,
                freeText: showsFreeTextField ? freeText : ""
            )
            onCancelled(cancelledBooking)
        } catch {
            errorMessage = userMessage(for: error)
        }
    }

    private func userMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.userMessage
        }

        return "Unable to cancel this booking. Please try again."
    }
}
