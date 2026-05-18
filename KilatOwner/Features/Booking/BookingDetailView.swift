import SwiftUI
import KilatUI

struct BookingDetailView: View {
    @Bindable var viewModel: BookingDetailViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.xl) {
                header

                if let booking = viewModel.booking {
                    bookingContent(booking)
                } else {
                    loadingCard
                }
            }
            .padding(.horizontal, Tokens.Space.lg)
            .padding(.vertical, Tokens.Space.xxl)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .sheet(isPresented: safariSheetBinding) {
            if let redirectURL = viewModel.safariURL {
                PaymentSafariSheet(redirectURL: redirectURL) {
                    Task {
                        await viewModel.safariDismissed()
                    }
                }
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private var safariSheetBinding: Binding<Bool> {
        Binding {
            viewModel.safariURL != nil
        } set: { isPresented in
            guard !isPresented, viewModel.safariURL != nil else { return }
            Task {
                await viewModel.safariDismissed()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            Text("Kilat Owner")
                .font(Tokens.FontRole.caption)
                .foregroundStyle(Tokens.Color.primary)

            Text("Booking detail")
                .font(Tokens.FontRole.displayL)
                .foregroundStyle(Tokens.Color.textPrimary)

            Text(viewModel.booking?.bookingNumber ?? viewModel.bookingID)
                .font(Tokens.FontRole.body)
                .foregroundStyle(Tokens.Color.textSecondary)
                .lineLimit(1)
        }
    }

    private func bookingContent(_ booking: BookingDTO) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.lg) {
            mapSection(booking)
            routeCard(booking)
            PetCardView(petSpec: booking.petSpec)
            notesCard(booking)
            PriceBreakdownView(booking: booking, payment: viewModel.payment)
            actionCard(booking)
        }
    }

    private func mapSection(_ booking: BookingDTO) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.md) {
            HStack(alignment: .center) {
                StatusBadge(status: booking.status.detailBadgeStatus, pulses: booking.status == .inProgress)

                Spacer(minLength: Tokens.Space.sm)

                Text(viewModel.paymentStatusText)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .lineLimit(1)
            }

            MapPlaceholder(
                pickup: Coordinate(lat: booking.pickupAddress.latitude, lng: booking.pickupAddress.longitude),
                dropoff: Coordinate(lat: booking.dropoffAddress.latitude, lng: booking.dropoffAddress.longitude),
                mode: .compact
            )
        }
    }

    private func routeCard(_ booking: BookingDTO) -> some View {
        Card {
            VStack(alignment: .leading, spacing: Tokens.Space.md) {
                routeRow(
                    icon: "mappin.circle.fill",
                    title: "Pickup",
                    address: booking.pickupAddress.line1,
                    detail: booking.pickupAddress.city
                )

                Divider()
                    .background(Tokens.Color.separator)

                routeRow(
                    icon: "flag.checkered.circle.fill",
                    title: "Dropoff",
                    address: booking.dropoffAddress.line1,
                    detail: booking.dropoffAddress.city
                )
            }
        }
    }

    private func routeRow(icon: String, title: String, address: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: Tokens.Space.md) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Tokens.Color.primary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)

                Text(address)
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(detail)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)
            }
        }
    }

    private func notesCard(_ booking: BookingDTO) -> some View {
        Card {
            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                Text("Notes")
                    .font(Tokens.FontRole.titleM)
                    .foregroundStyle(Tokens.Color.textPrimary)

                Text(booking.notes.isEmpty ? "No notes added" : booking.notes)
                    .font(Tokens.FontRole.body)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func actionCard(_ booking: BookingDTO) -> some View {
        Card {
            VStack(alignment: .leading, spacing: Tokens.Space.md) {
                VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                    Text("Next step")
                        .font(Tokens.FontRole.titleM)
                        .foregroundStyle(Tokens.Color.textPrimary)

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(Tokens.FontRole.caption)
                            .foregroundStyle(Tokens.Color.destructive)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if viewModel.safariURL != nil {
                        Text("Secure checkout is ready.")
                            .font(Tokens.FontRole.caption)
                            .foregroundStyle(Tokens.Color.textSecondary)
                    }
                }

                PrimaryButton(
                    title: viewModel.primaryButtonTitle,
                    icon: viewModel.primaryButtonIcon,
                    isLoading: viewModel.primaryButtonIsLoading,
                    isEnabled: viewModel.primaryButtonIsEnabled
                ) {
                    Task {
                        await viewModel.primaryTapped()
                    }
                }

                if viewModel.showsCancelCTA {
                    SecondaryButton(title: "Cancel booking", icon: "xmark.circle") {
                        viewModel.cancelTapped()
                    }
                }

                if viewModel.showsCancelReasonSheet {
                    Text("Choose a cancellation reason to continue.")
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.textSecondary)
                }
            }
        }
    }

    private var loadingCard: some View {
        Card {
            HStack(spacing: Tokens.Space.md) {
                ProgressView()
                    .tint(Tokens.Color.primary)

                Text(viewModel.errorMessage ?? "Loading booking")
                    .font(Tokens.FontRole.body)
                    .foregroundStyle(Tokens.Color.textSecondary)
            }
        }
    }
}

private extension BookingStatus {
    var detailBadgeStatus: StatusBadge.Status {
        switch self {
        case .requested:
            return .pending
        case .accepted:
            return .confirmed
        case .inProgress:
            return .enroute
        case .delivered, .completed:
            return .delivered
        case .cancelled:
            return .cancelled
        }
    }
}

#Preview {
    BookingDetailView(
        viewModel: BookingDetailViewModel(
            bookingID: SampleData.activeBookingID.uuidString,
            bookingRepository: StubBookingRepository(),
            paymentRepository: StubPaymentRepository(),
            initialBooking: SampleData.activeBooking,
            initialPayment: SampleData.payment
        )
    )
}
