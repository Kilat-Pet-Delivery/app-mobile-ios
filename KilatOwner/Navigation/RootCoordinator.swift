import Foundation
import Observation

@MainActor
@Observable
final class RootCoordinator {
    var path: [OwnerRoute]

    init(path: [OwnerRoute] = []) {
        self.path = path
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
