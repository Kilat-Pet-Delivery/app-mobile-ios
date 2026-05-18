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
            PlaceholderDashboardView(
                useStubs: environment.useStubs,
                coordinator: coordinator
            )
                .navigationDestination(for: OwnerRoute.self) { route in
                    RouteResolver.view(
                        for: route,
                        environment: environment,
                        coordinator: coordinator
                    )
                }
        }
    }
}

private struct PlaceholderDashboardView: View {
    let useStubs: Bool
    let coordinator: RootCoordinator

    private var routes: [OwnerRoute] {
        [
            .login,
            .forgotPassword,
            .resetSent,
            .signup,
            .welcome,
            .home,
            .services(prefilledPetID: SampleData.mochiID.uuidString),
            .bookingDetail(bookingID: SampleData.activeBookingID.uuidString),
            .bookingConfirmed(bookingID: SampleData.activeBookingID.uuidString),
            .cancelReason(bookingID: SampleData.activeBookingID.uuidString),
            .tracking(bookingID: SampleData.activeBookingID.uuidString),
            .notifications,
            .pushPreview
        ]
    }

    var body: some View {
        VStack(spacing: Tokens.Space.lg) {
            HStack {
                Spacer()

                CircleBtn(icon: "bell", variant: .surface) {
                    coordinator.push(.notifications)
                }
            }
            .frame(maxWidth: 320)

            Image(systemName: "pawprint.fill")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(Tokens.Color.primary)

            Text("Kilat Owner - rewrite in progress")
                .font(Tokens.FontRole.titleL)
                .foregroundStyle(Tokens.Color.textPrimary)
                .multilineTextAlignment(.center)

            Text(useStubs ? "Stub mode enabled" : "Live mode")
                .font(Tokens.FontRole.caption)
                .foregroundStyle(Tokens.Color.textSecondary)

            routeGrid
        }
        .padding(Tokens.Space.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Tokens.Color.background.ignoresSafeArea())
    }

    private var routeGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: Tokens.Space.sm),
                GridItem(.flexible(), spacing: Tokens.Space.sm)
            ],
            spacing: Tokens.Space.sm
        ) {
            ForEach(routes, id: \.self) { route in
                Button {
                    coordinator.push(route)
                } label: {
                    HStack(spacing: Tokens.Space.xs) {
                        Text(route.placeholderTitle)
                            .font(Tokens.FontRole.caption)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)

                        Spacer(minLength: Tokens.Space.xs)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(Tokens.Color.textPrimary)
                    .padding(.horizontal, Tokens.Space.sm)
                    .frame(height: 42)
                    .background(Tokens.Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous)
                            .stroke(Tokens.Color.separator, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: 430)
    }
}

#Preview {
    RootView(environment: .preview)
}
