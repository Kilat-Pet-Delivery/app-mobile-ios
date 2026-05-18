import Foundation
import Observation

@MainActor
@Observable
final class RootCoordinator {
    var rootRoute: OwnerRoute?
    var path: [OwnerRoute]

    init(rootRoute: OwnerRoute? = nil, path: [OwnerRoute] = []) {
        self.rootRoute = rootRoute
        self.path = path
    }

    func setRoot(_ route: OwnerRoute) {
        rootRoute = route
        path.removeAll()
    }

    func push(_ route: OwnerRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}
