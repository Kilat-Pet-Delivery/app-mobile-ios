import SwiftUI
import KilatUI

struct BookingConfirmedView: View {
    @Bindable var viewModel: BookingConfirmedViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.xl) {
                header
                runnerCard
                tripCard
                actionSection
            }
            .padding(.horizontal, Tokens.Space.lg)
            .padding(.vertical, Tokens.Space.xxl)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .sheet(isPresented: $viewModel.showsCancelReasonSheet) {
            CancelReasonSheet(
                viewModel: viewModel.makeCancelReasonViewModel(),
                onKeepBooking: {
                    viewModel.dismissCancelSheet()
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .task {
            viewModel.startETARefresh()
        }
        .onDisappear {
            viewModel.stopETARefresh()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            Text("Kilat Owner")
                .font(Tokens.FontRole.caption)
                .foregroundStyle(Tokens.Color.primary)

            Text("Booking confirmed")
                .font(Tokens.FontRole.displayL)
                .foregroundStyle(Tokens.Color.textPrimary)

            Text("Payment is secured. Your runner is assigned.")
                .font(Tokens.FontRole.body)
                .foregroundStyle(Tokens.Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var runnerCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Tokens.Space.lg) {
                HStack(alignment: .center, spacing: Tokens.Space.md) {
                    Avatar(
                        name: viewModel.runner.fullName,
                        size: 64,
                        bg: Tokens.Color.primary,
                        fg: Tokens.Color.onPrimary
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.runner.fullName)
                            .font(Tokens.FontRole.titleL)
                            .foregroundStyle(Tokens.Color.textPrimary)

                        Text("\(viewModel.runner.vehicleDescription) · \(viewModel.runner.rating, specifier: "%.1f") rating")
                            .font(Tokens.FontRole.caption)
                            .foregroundStyle(Tokens.Color.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: Tokens.Space.sm)
                }

                HStack(alignment: .center, spacing: Tokens.Space.md) {
                    etaBadge

                    Spacer(minLength: Tokens.Space.sm)

                    CircleBtn(icon: "message.fill", size: 44, variant: .tonal) {}
                    CircleBtn(icon: "phone.fill", size: 44, variant: .tonal) {}
                }
            }
        }
    }

    private var etaBadge: some View {
        HStack(spacing: Tokens.Space.sm) {
            Image(systemName: viewModel.isLateRunner ? "clock.badge.exclamationmark.fill" : "clock.fill")
                .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 2) {
                Text("ETA")
                    .font(Tokens.FontRole.caption)

                Text(viewModel.etaDisplayText)
                    .font(Tokens.FontRole.label)
                    .lineLimit(1)
            }
        }
        .foregroundStyle(viewModel.isLateRunner ? lateAccent : Tokens.Color.onPrimaryTonal)
        .padding(.horizontal, Tokens.Space.md)
        .padding(.vertical, Tokens.Space.sm)
        .background(
            RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous)
                .fill(viewModel.isLateRunner ? lateAccent.opacity(0.12) : Tokens.Color.primaryTonal)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous)
                .stroke(viewModel.isLateRunner ? lateAccent.opacity(0.45) : Color.clear, lineWidth: 1)
        )
    }

    private var tripCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Tokens.Space.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(viewModel.booking.petSpec.name)
                            .font(Tokens.FontRole.titleM)
                            .foregroundStyle(Tokens.Color.textPrimary)

                        Text(viewModel.routeSummaryText)
                            .font(Tokens.FontRole.caption)
                            .foregroundStyle(Tokens.Color.textSecondary)
                    }

                    Spacer(minLength: Tokens.Space.sm)

                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Tokens.Color.primary)
                }

                Divider()
                    .background(Tokens.Color.separator)

                routeRow(
                    icon: "mappin.circle.fill",
                    title: "Pickup",
                    detail: viewModel.booking.pickupAddress.line1
                )

                routeRow(
                    icon: "flag.checkered.circle.fill",
                    title: "Dropoff",
                    detail: viewModel.booking.dropoffAddress.line1
                )
            }
        }
    }

    private func routeRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: Tokens.Space.sm) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Tokens.Color.primary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)

                Text(detail)
                    .font(Tokens.FontRole.body)
                    .foregroundStyle(Tokens.Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var actionSection: some View {
        VStack(spacing: Tokens.Space.sm) {
            PrimaryButton(title: "Track runner", icon: "location.fill") {
                viewModel.trackTapped()
            }

            SecondaryButton(title: "Cancel booking", icon: "xmark.circle") {
                viewModel.cancelTapped()
            }
        }
    }

    private var lateAccent: Color {
        Color(red: 0.84, green: 0.56, blue: 0.06)
    }
}

#Preview {
    BookingConfirmedView(
        viewModel: BookingConfirmedViewModel(
            bookingID: SampleData.activeBookingID.uuidString,
            booking: SampleData.activeBooking,
            bookingRepository: StubBookingRepository()
        )
    )
}
