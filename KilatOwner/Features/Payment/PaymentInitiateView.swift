import SwiftUI

struct PaymentInitiateView: View {
    let booking: Booking
    let customerEmail: String
    let onFinished: () async -> Void

    @State private var viewModel = PaymentInitiateViewModel()
    @State private var safariURL: URL?

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isInitiating || viewModel.isPolling {
                ProgressView(viewModel.isPolling ? "Checking payment" : "Starting payment")
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            if viewModel.pollingState == .success {
                Text("Payment received.")
                    .foregroundStyle(.green)
            } else if viewModel.pollingState == .timedOut {
                Text("Payment is still processing. Pull to refresh the booking in a moment.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .task {
            await viewModel.start(
                bookingId: booking.id,
                amountCents: booking.amountCents,
                currency: booking.currency,
                email: customerEmail
            )
            safariURL = viewModel.redirectURL
        }
        .sheet(item: $safariURL) { url in
            SafariCoordinator(url: url) {
                Task {
                    await viewModel.onSafariDismissed(bookingId: booking.id)
                    await onFinished()
                }
            }
        }
    }
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}
