import SwiftUI

struct BookingDetailView: View {
    @Environment(AppSession.self) private var session
    @Bindable private var viewModel: BookingDetailViewModel
    @State private var showingPayment = false

    init(viewModel: BookingDetailViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if let booking = viewModel.booking {
                    statusHeader(booking)
                    info(booking)
                    primaryActionButton
                } else if let errorMessage = viewModel.errorMessage {
                    ContentUnavailableView("Could not load booking", systemImage: "doc.text", description: Text(errorMessage))
                }
            }
            .padding(20)
        }
        .navigationTitle("Booking")
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.onAppear()
        }
        .sheet(isPresented: $showingPayment) {
            if let booking = viewModel.booking {
                PaymentInitiateView(
                    booking: booking,
                    customerEmail: session.currentUser?.email ?? "owner@kilat.my"
                ) {
                    await viewModel.refresh()
                }
            }
        }
    }

    private func statusHeader(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(booking.status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.title2.bold())
            Text(booking.bookingNumber)
                .foregroundStyle(.secondary)
        }
    }

    private func info(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(booking.petSpec.name, systemImage: "pawprint.fill")
            Label(booking.pickupAddress.singleLineLabel, systemImage: "mappin.and.ellipse")
            Label(booking.dropoffAddress.singleLineLabel, systemImage: "flag.checkered")
            Text("\(booking.currency) \(Double(booking.amountCents) / 100, specifier: "%.2f")")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var primaryActionButton: some View {
        switch viewModel.primaryAction {
        case .pay:
            Button("Pay Now") {
                showingPayment = true
            }
                .buttonStyle(.borderedProminent)
        case .waiting:
            Text("Waiting for a runner.")
                .foregroundStyle(.secondary)
        case .trackLive:
            Button("Track Live") {}
                .buttonStyle(.borderedProminent)
        case .completed:
            Text("Delivery completed.")
                .foregroundStyle(.green)
        case .none:
            EmptyView()
        }
    }
}
