import Foundation

enum OwnerRoute: Hashable {
    case login
    case forgotPassword
    case resetSent
    case signup
    case welcome
    case home
    case services(prefilledPetID: String?)
    case bookingDetail(bookingID: String)
    case bookingConfirmed(bookingID: String)
    case cancelReason(bookingID: String)
    case tracking(bookingID: String)
    case notifications
    case pushPreview
}

extension OwnerRoute {
    var placeholderTitle: String {
        switch self {
        case .login:
            return "Login"
        case .forgotPassword:
            return "Forgot Password"
        case .resetSent:
            return "Reset Sent"
        case .signup:
            return "Sign Up"
        case .welcome:
            return "Welcome"
        case .home:
            return "Home"
        case .services:
            return "Services"
        case .bookingDetail:
            return "Booking Detail"
        case .bookingConfirmed:
            return "Booking Confirmed"
        case .cancelReason:
            return "Cancel Reason"
        case .tracking:
            return "Tracking"
        case .notifications:
            return "Notifications"
        case .pushPreview:
            return "Push Preview"
        }
    }
}
