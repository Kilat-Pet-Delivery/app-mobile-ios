import SwiftUI

@main
struct KilatOwnerApp: App {
    private let environment = AppEnvironment.current

    var body: some Scene {
        WindowGroup {
            RootView(environment: environment)
        }
    }
}
