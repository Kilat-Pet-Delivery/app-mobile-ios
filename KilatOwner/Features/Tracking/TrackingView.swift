import SwiftUI
import KilatUI

struct TrackingView: View {
    @Bindable var viewModel: TrackingViewModel
    var subscribesOnAppear = true

    var body: some View {
        ZStack {
            MapPlaceholder(
                pickup: viewModel.pickupCoordinate,
                dropoff: viewModel.dropoffCoordinate,
                mode: .full
            )
            .ignoresSafeArea()

            runnerMarker

            overlayChrome
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if subscribesOnAppear {
                viewModel.onAppear()
            }
        }
        .onDisappear {
            if subscribesOnAppear {
                viewModel.onDisappear()
            }
        }
    }

    private var overlayChrome: some View {
        VStack(spacing: Tokens.Space.md) {
            topBar

            if viewModel.showsReconnectingBanner {
                reconnectingBanner
            }

            Spacer(minLength: Tokens.Space.md)

            RunnerCard(
                runner: viewModel.runner,
                etaText: viewModel.etaText,
                speedText: viewModel.speedText,
                statusText: viewModel.statusText,
                connectionState: viewModel.connectionState,
                onChat: viewModel.chatTapped,
                onCall: viewModel.callTapped
            )
            .frame(maxWidth: .infinity)
            .padding(.bottom, Tokens.Space.lg)
        }
        .padding(.horizontal, Tokens.Space.lg)
        .padding(.top, Tokens.Space.md)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var topBar: some View {
        HStack(spacing: Tokens.Space.sm) {
            CircleBtn(icon: "chevron.left", size: 46, variant: .glass) {
                viewModel.backTapped()
            }

            Spacer(minLength: Tokens.Space.sm)

            HStack(spacing: Tokens.Space.xs) {
                Image(systemName: "location.fill")
                    .font(.system(size: 13, weight: .semibold))

                Text(viewModel.connectionState.displayText)
                    .font(Tokens.FontRole.caption)
                    .lineLimit(1)
            }
            .foregroundStyle(Tokens.Color.textPrimary)
            .padding(.horizontal, Tokens.Space.md)
            .padding(.vertical, Tokens.Space.sm)
            .background(Color.white.opacity(0.58))
            .clipShape(Capsule())
            .tokenShadow(Tokens.Shadow.press)
        }
    }

    private var reconnectingBanner: some View {
        HStack(spacing: Tokens.Space.sm) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 16, weight: .semibold))

            Text("Reconnecting to live runner updates")
                .font(Tokens.FontRole.caption)
                .lineLimit(1)

            Spacer(minLength: Tokens.Space.xs)
        }
        .foregroundStyle(Color(red: 0.55, green: 0.34, blue: 0.02))
        .padding(.horizontal, Tokens.Space.md)
        .padding(.vertical, Tokens.Space.sm)
        .background(Color(red: 1.0, green: 0.89, blue: 0.64).opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
        .tokenShadow(Tokens.Shadow.card)
    }

    private var runnerMarker: some View {
        GeometryReader { proxy in
            let point = mapPoint(for: viewModel.runnerCoordinate, in: proxy.size)

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.92))
                    .frame(width: 46, height: 46)

                Circle()
                    .fill(Tokens.Color.primary)
                    .frame(width: 34, height: 34)

                Image(systemName: "location.north.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Tokens.Color.onPrimary)
            }
            .shadow(color: Color.black.opacity(0.16), radius: 12, x: 0, y: 6)
            .position(point)
        }
        .allowsHitTesting(false)
    }

    private func mapPoint(for coordinate: Coordinate, in size: CGSize) -> CGPoint {
        let pickup = viewModel.pickupCoordinate
        let dropoff = viewModel.dropoffCoordinate
        let padding = max(min(size.width, size.height) * 0.18, 34)
        let minLat = min(pickup.lat, dropoff.lat)
        let maxLat = max(pickup.lat, dropoff.lat)
        let minLng = min(pickup.lng, dropoff.lng)
        let maxLng = max(pickup.lng, dropoff.lng)
        let latSpan = max(maxLat - minLat, 0.000_001)
        let lngSpan = max(maxLng - minLng, 0.000_001)
        let xProgress = (coordinate.lng - minLng) / lngSpan
        let yProgress = 1 - ((coordinate.lat - minLat) / latSpan)
        let clampedX = min(max(xProgress, 0), 1)
        let clampedY = min(max(yProgress, 0), 1)

        return CGPoint(
            x: padding + clampedX * max(size.width - (padding * 2), 1),
            y: padding + clampedY * max(size.height - (padding * 2), 1)
        )
    }
}

#Preview {
    TrackingView(
        viewModel: TrackingViewModel(
            bookingID: SampleData.activeBookingID.uuidString,
            booking: SampleData.activeBooking,
            trackingRepository: StubTrackingRepository(),
            initialConnectionState: .connected
        )
    )
}
