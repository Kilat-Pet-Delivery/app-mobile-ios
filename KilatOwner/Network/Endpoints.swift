import Foundation

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

struct APIEndpoint: Equatable, Sendable {
    let method: HTTPMethod
    let path: String
    let queryItems: [URLQueryItem]
    let requiresAuth: Bool

    init(
        method: HTTPMethod,
        path: String,
        queryItems: [URLQueryItem] = [],
        requiresAuth: Bool = true
    ) {
        self.method = method
        self.path = path
        self.queryItems = queryItems
        self.requiresAuth = requiresAuth
    }
}

enum Endpoints {
    enum Auth {
        static let login = APIEndpoint(method: .post, path: "/api/v1/auth/login", requiresAuth: false)
        static let register = APIEndpoint(method: .post, path: "/api/v1/auth/register", requiresAuth: false)
        static let logout = APIEndpoint(method: .post, path: "/api/v1/auth/logout")
        static let forgotPassword = APIEndpoint(method: .post, path: "/api/v1/auth/forgot-password", requiresAuth: false)
        static let resetPassword = APIEndpoint(method: .post, path: "/api/v1/auth/reset-password", requiresAuth: false)
        static let profile = APIEndpoint(method: .get, path: "/api/v1/auth/profile")
        static let refresh = APIEndpoint(method: .post, path: "/api/v1/auth/refresh", requiresAuth: false)
    }

    enum Booking {
        static let create = APIEndpoint(method: .post, path: "/api/v1/bookings")
        static let active = APIEndpoint(
            method: .get,
            path: "/api/v1/bookings",
            queryItems: [URLQueryItem(name: "status", value: "active")]
        )
        static let recent = APIEndpoint(
            method: .get,
            path: "/api/v1/bookings",
            queryItems: [
                URLQueryItem(name: "status", value: "completed"),
                URLQueryItem(name: "limit", value: "5")
            ]
        )

        static func detail(id: String) -> APIEndpoint {
            APIEndpoint(method: .get, path: "/api/v1/bookings/\(id)")
        }

        static func cancel(id: String) -> APIEndpoint {
            APIEndpoint(method: .post, path: "/api/v1/bookings/\(id)/cancel")
        }
    }

    enum Payment {
        static let initiate = APIEndpoint(method: .post, path: "/api/v1/payments/initiate")

        static func byBooking(bookingID: String) -> APIEndpoint {
            APIEndpoint(method: .get, path: "/api/v1/payments/booking/\(bookingID)")
        }
    }

    enum Pets {
        static let mine = APIEndpoint(method: .get, path: "/api/v1/users/me/pets")
        static let create = APIEndpoint(method: .post, path: "/api/v1/users/me/pets")
    }

    enum Notifications {
        static func list(cursor: String? = nil, limit: Int = 20) -> APIEndpoint {
            var queryItems = [URLQueryItem(name: "limit", value: String(limit))]
            if let cursor, !cursor.isEmpty {
                queryItems.append(URLQueryItem(name: "cursor", value: cursor))
            }

            return APIEndpoint(
                method: .get,
                path: "/api/v1/notifications",
                queryItems: queryItems
            )
        }

        static func markRead(id: String) -> APIEndpoint {
            APIEndpoint(method: .post, path: "/api/v1/notifications/\(id)/read")
        }
    }

    enum Tracking {
        static func webSocketURL(baseURL: URL, bookingID: String) -> URL? {
            guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
                return nil
            }

            let currentScheme = components.scheme
            components.scheme = currentScheme == "https" ? "wss" : "ws"
            components.path = "/tracking"
            components.queryItems = [URLQueryItem(name: "booking_id", value: bookingID)]
            return components.url
        }
    }
}
