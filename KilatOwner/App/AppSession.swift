import Foundation
import Observation

@Observable
final class AppSession {
    enum State: Equatable {
        case bootstrapping
        case unauthenticated
        case authenticated
    }

    @ObservationIgnored private let tokenStore: TokenStore

    var state: State
    var isAuthenticated: Bool
    var hasBootstrapped: Bool
    var activeBookingId: String?
    var currentUser: User?

    init(tokenStore: TokenStore = KeychainStore()) {
        self.tokenStore = tokenStore
        state = .bootstrapping
        isAuthenticated = false
        hasBootstrapped = false
    }

    func markAuthenticated(user: User? = nil) {
        currentUser = user
        isAuthenticated = true
        hasBootstrapped = true
        state = .authenticated
    }

    func markUnauthenticated() {
        currentUser = nil
        isAuthenticated = false
        hasBootstrapped = true
        state = .unauthenticated
    }

    func logout() {
        tokenStore.clear()
        activeBookingId = nil
        markUnauthenticated()
    }
}
