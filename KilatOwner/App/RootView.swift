import SwiftUI
import KilatUI

struct RootView: View {
    private let environment: AppEnvironment
    @State private var coordinator: RootCoordinator

    @MainActor
    init(environment: AppEnvironment = .current) {
        self.environment = environment
        _coordinator = State(initialValue: RootCoordinator())
    }

    var body: some View {
        @Bindable var coordinator = coordinator

        NavigationStack(path: $coordinator.path) {
            PlaceholderDashboardView(useStubs: environment.useStubs)
                .navigationDestination(for: OwnerRoute.self) { route in
                    PlaceholderRouteView(route: route)
                }
        }
    }
}

private struct PlaceholderDashboardView: View {
    let useStubs: Bool

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()

                CircleBtn(icon: "bell", variant: .surface) {}
            }
            .frame(maxWidth: 320)

            Image(systemName: "pawprint.fill")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(.orange)

            Text("Kilat Owner - rewrite in progress")
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)

            Text(useStubs ? "Stub mode enabled" : "Live mode")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

private struct PlaceholderRouteView: View {
    let route: OwnerRoute

    var body: some View {
        Text(route.placeholderTitle)
            .font(.title2.weight(.semibold))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(route.placeholderTitle)
    }
}

#Preview {
    RootView(environment: .preview)
}
