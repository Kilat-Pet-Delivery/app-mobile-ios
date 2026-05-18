import SwiftUI
import KilatUI

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel

    private let columns = [
        GridItem(.flexible(), spacing: Tokens.Space.sm),
        GridItem(.flexible(), spacing: Tokens.Space.sm)
    ]

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Space.xl) {
                    header
                    activeOrEmptySection
                    servicesSection
                    petsSection
                    recentTripsSection
                }
                .padding(.horizontal, Tokens.Space.lg)
                .padding(.vertical, Tokens.Space.xxl)
                .frame(width: min(proxy.size.width, 560), alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(Tokens.Color.background.ignoresSafeArea())
            .task {
                await viewModel.loadIfNeeded()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: Tokens.Space.md) {
            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                Text("Kilat Owner")
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.primary)

                Text("Home")
                    .font(Tokens.FontRole.displayL)
                    .foregroundStyle(Tokens.Color.textPrimary)

                Text("Your pet trips at a glance.")
                    .font(Tokens.FontRole.body)
                    .foregroundStyle(Tokens.Color.textSecondary)
            }

            Spacer(minLength: Tokens.Space.sm)

            notificationBadge
        }
    }

    @ViewBuilder
    private var notificationBadge: some View {
        if viewModel.unreadNotificationCount > 0 {
            HStack(spacing: Tokens.Space.xs) {
                Image(systemName: "bell.fill")
                Text("\(viewModel.unreadNotificationCount)")
            }
            .font(Tokens.FontRole.caption)
            .foregroundStyle(Tokens.Color.onPrimary)
            .padding(.horizontal, Tokens.Space.sm)
            .padding(.vertical, Tokens.Space.xs)
            .background(Tokens.Color.primary)
            .clipShape(Capsule())
        } else {
            CircleBtn(icon: "bell", size: 44, variant: .surface) {}
        }
    }

    @ViewBuilder
    private var activeOrEmptySection: some View {
        if let activeBooking = viewModel.activeBooking {
            ActiveBookingCard(
                booking: activeBooking,
                onTrack: viewModel.trackActiveBookingTapped,
                onChat: {}
            )
        } else if viewModel.showsFirstRunCTA {
            firstRunCard
        }
    }

    private var firstRunCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Tokens.Space.md) {
                ZStack {
                    Circle()
                        .fill(Tokens.Color.primaryTonal)

                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Tokens.Color.onPrimaryTonal)
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                    Text("Ready for your first run")
                        .font(Tokens.FontRole.titleL)
                        .foregroundStyle(Tokens.Color.textPrimary)

                    Text("Book transport for vet visits, grooming, daycare, and supply runs.")
                        .font(Tokens.FontRole.body)
                        .foregroundStyle(Tokens.Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: Tokens.Space.sm) {
                    PrimaryButton(title: "Book your first run", icon: "arrow.right") {
                        viewModel.bookFirstRunTapped()
                    }

                    SecondaryButton(title: "Add a pet", icon: "plus") {
                        viewModel.addPetTapped()
                    }
                }
            }
        }
    }

    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.md) {
            sectionHeader(title: "Services", icon: "square.grid.2x2.fill")

            LazyVGrid(columns: columns, spacing: Tokens.Space.sm) {
                ForEach(viewModel.services) { service in
                    ServiceTile(service: service) {
                        viewModel.serviceTileTapped(service)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var petsSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.md) {
            sectionHeader(title: "My pets", icon: "pawprint.fill")

            if viewModel.hasPets {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Tokens.Space.sm) {
                        ForEach(viewModel.pets) { pet in
                            PetRow(pet: pet)
                        }
                    }
                    .padding(.vertical, 2)
                }
            } else {
                emptyInlineCard(
                    title: "No pets yet",
                    subtitle: "Add pet details before the next booking.",
                    icon: "plus.circle.fill",
                    buttonTitle: "Add a pet",
                    buttonIcon: "plus",
                    action: viewModel.addPetTapped
                )
            }
        }
    }

    @ViewBuilder
    private var recentTripsSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.md) {
            sectionHeader(title: "Recent trips", icon: "clock.arrow.circlepath")

            if viewModel.recentTrips.isEmpty {
                emptyInlineCard(
                    title: "No completed trips",
                    subtitle: "Finished runs will appear here.",
                    icon: "tray.fill",
                    buttonTitle: "Browse services",
                    buttonIcon: "square.grid.2x2.fill",
                    action: viewModel.bookFirstRunTapped
                )
            } else {
                Card {
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.recentTrips.enumerated()), id: \.element.id) { index, trip in
                            RecentTripRow(booking: trip)

                            if index < viewModel.recentTrips.count - 1 {
                                Divider()
                                    .background(Tokens.Color.separator)
                            }
                        }
                    }
                }
            }
        }
    }

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: Tokens.Space.xs) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Tokens.Color.primary)

            Text(title)
                .font(Tokens.FontRole.titleM)
                .foregroundStyle(Tokens.Color.textPrimary)
        }
    }

    private func emptyInlineCard(
        title: String,
        subtitle: String,
        icon: String,
        buttonTitle: String,
        buttonIcon: String,
        action: @escaping () -> Void
    ) -> some View {
        Card {
            HStack(alignment: .top, spacing: Tokens.Space.md) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Tokens.Color.primary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                    Text(title)
                        .font(Tokens.FontRole.label)
                        .foregroundStyle(Tokens.Color.textPrimary)

                    Text(subtitle)
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    SecondaryButton(title: buttonTitle, icon: buttonIcon, action: action)
                        .padding(.top, Tokens.Space.xs)
                }
            }
        }
    }
}

#Preview {
    HomeView(
        viewModel: HomeViewModel(
            homeRepository: StubHomeRepository(),
            initialSnapshot: SampleData.homeSnapshot
        )
    )
}
