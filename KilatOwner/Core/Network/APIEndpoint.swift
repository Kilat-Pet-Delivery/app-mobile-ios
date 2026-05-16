import Foundation

enum APIEndpoint: Equatable {
    case register
    case login
    case refresh
    case logout
    case profile
    case me
    case petshopsList(page: Int = 1, query: String? = nil)
    case petshopDetail(id: String)
    case createBooking
    case initiatePayment

    // Legacy runner endpoints retained while the owner app is built phase-by-phase.
    case runnerMe
    case runnerOnline
    case runnerOffline
    case runnerLocation
    case availableJobs(page: Int = 1, limit: Int = 20)
    case bookingDetail(id: String)
    case acceptBooking(id: String)
    case markPickup(id: String)
    case markDelivered(id: String)
    case trackingHistory(bookingId: String)
    case earnings(page: Int = 1, limit: Int = 20)

    var method: HTTPMethod {
        switch self {
        case .register, .login, .refresh, .logout, .createBooking, .initiatePayment,
                .runnerOnline, .runnerOffline, .runnerLocation,
                .acceptBooking, .markPickup, .markDelivered:
            return .post
        case .profile, .me, .petshopsList, .petshopDetail, .runnerMe, .availableJobs,
                .bookingDetail, .trackingHistory, .earnings:
            return .get
        }
    }

    var path: String {
        switch self {
        case .register:
            return "auth/register"
        case .login:
            return "auth/login"
        case .refresh:
            return "auth/refresh"
        case .logout:
            return "auth/logout"
        case .profile:
            return "auth/profile"
        case .me:
            return "auth/me"
        case .petshopsList:
            return "petshops"
        case let .petshopDetail(id):
            return "petshops/\(id)"
        case .createBooking:
            return "bookings"
        case .initiatePayment:
            return "payments/initiate"
        case .runnerMe:
            return "runners/me"
        case .runnerOnline:
            return "runners/me/online"
        case .runnerOffline:
            return "runners/me/offline"
        case .runnerLocation:
            return "runners/me/location"
        case .availableJobs:
            return "bookings"
        case let .bookingDetail(id):
            return "bookings/\(id)"
        case let .acceptBooking(id):
            return "bookings/\(id)/accept"
        case let .markPickup(id):
            return "bookings/\(id)/pickup"
        case let .markDelivered(id):
            return "bookings/\(id)/deliver"
        case let .trackingHistory(bookingId):
            return "bookings/\(bookingId)/tracking"
        case .earnings:
            // The backend currently derives runner earnings from completed bookings.
            return "bookings"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case let .petshopsList(page, query):
            var items = [
                URLQueryItem(name: "page", value: String(page))
            ]
            if let query, !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                items.append(URLQueryItem(name: "query", value: query))
            }
            return items
        case let .availableJobs(page, limit):
            return [
                URLQueryItem(name: "status", value: "requested"),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "limit", value: String(limit))
            ]
        case let .earnings(page, limit):
            return [
                URLQueryItem(name: "status", value: "completed"),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "limit", value: String(limit))
            ]
        default:
            return []
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .register, .login, .refresh:
            return false
        default:
            return true
        }
    }
}
