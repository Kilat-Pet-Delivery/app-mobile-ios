import Foundation

enum BookingStatus: String, Codable, CaseIterable, Equatable, Sendable {
    case requested
    case accepted
    case inProgress = "in_progress"
    case delivered
    case completed
    case cancelled

    var displayLabel: String {
        switch self {
        case .requested:
            return "Pending"
        case .accepted:
            return "Confirmed"
        case .inProgress:
            return "En route"
        case .delivered:
            return "Delivered"
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        }
    }

    var isTerminal: Bool {
        switch self {
        case .completed, .cancelled:
            return true
        case .requested, .accepted, .inProgress, .delivered:
            return false
        }
    }
}
