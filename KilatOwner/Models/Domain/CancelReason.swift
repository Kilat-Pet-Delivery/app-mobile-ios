import Foundation

enum CancelReason: String, Codable, CaseIterable, Equatable, Identifiable, Sendable {
    case changedMind = "changed_mind"
    case foundAnotherOption = "found_another_option"
    case tookTooLong = "took_too_long"
    case wrongBookingDetails = "wrong_booking_details"
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .changedMind:
            return "Changed my mind"
        case .foundAnotherOption:
            return "Found another option"
        case .tookTooLong:
            return "Took too long"
        case .wrongBookingDetails:
            return "Wrong booking details"
        case .other:
            return "Other"
        }
    }

    func wireReason(freeText: String = "") -> String {
        let trimmedText = freeText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard self == .other, !trimmedText.isEmpty else {
            return rawValue
        }
        return "\(rawValue): \(trimmedText)"
    }
}
