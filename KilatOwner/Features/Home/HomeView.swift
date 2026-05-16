import SwiftUI

struct HomeView: View {
    @Bindable private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if let activeBooking = viewModel.activeBooking {
                        activeBookingCard(activeBooking)
                    } else {
                        noActiveBookingCard
                    }

                    browseButton

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Kilat")
            .toolbar {
                Menu {
                    Button("Logout", role: .destructive) {
                        viewModel.logout()
                    }
                } label: {
                    Image(systemName: "person.crop.circle")
                }
            }
            .task {
                await viewModel.onAppear()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hi\(welcomeSuffix)")
                .font(.largeTitle.bold())
            Text("Book trusted pet delivery and keep an eye on every trip.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func activeBookingCard(_ booking: ActiveBookingSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Booking")
                    .font(.headline)
                Spacer()
                Text(booking.status.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.blue.opacity(0.12), in: Capsule())
                    .foregroundStyle(.blue)
            }

            Text(booking.petName)
                .font(.title3.weight(.semibold))

            VStack(alignment: .leading, spacing: 6) {
                Label(booking.pickupAddress, systemImage: "mappin.and.ellipse")
                Label(booking.dropoffAddress, systemImage: "flag.checkered")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            NavigationLink("View Booking") {
                Text("Booking detail arrives in Phase 5.")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var noActiveBookingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No active booking")
                .font(.headline)
            Text("Start by browsing pet shops, then create a delivery from the shop detail screen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var browseButton: some View {
        NavigationLink {
            Text("Pet shop browsing arrives in Phase 4.")
        } label: {
            Label("Browse Pet Shops", systemImage: "storefront.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    private var welcomeSuffix: String {
        guard let name = viewModel.user?.displayName, !name.isEmpty else {
            return ""
        }
        return ", \(name)"
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel(appSession: AppSession()))
}
