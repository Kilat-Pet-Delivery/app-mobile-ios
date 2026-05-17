import Foundation

struct AppEnvironment {
    let useStubs: Bool

    static var current: AppEnvironment {
        AppEnvironment(
            useStubs: ProcessInfo.processInfo.environment["KILAT_OWNER_STUB"] == "1"
        )
    }

    static let preview = AppEnvironment(useStubs: true)
}
