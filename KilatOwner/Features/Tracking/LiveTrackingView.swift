import MapKit
import SwiftUI

struct LiveTrackingView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var viewModel: LiveTrackingViewModel

    init(viewModel: LiveTrackingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map {
                if let pickup = viewModel.pickupCoord {
                    Marker("Pickup", systemImage: "mappin.and.ellipse", coordinate: pickup)
                }
                if let dropoff = viewModel.dropoffCoord {
                    Marker("Dropoff", systemImage: "flag.checkered", coordinate: dropoff)
                }
                if let runner = viewModel.runnerCoordinate {
                    Marker("Runner", systemImage: "bicycle", coordinate: runner)
                }
                if viewModel.polylinePoints.count > 1 {
                    MapPolyline(coordinates: viewModel.polylinePoints)
                        .stroke(.blue, lineWidth: 4)
                }
            }
            .ignoresSafeArea(edges: .bottom)

            statusBanner
                .padding()
        }
        .navigationTitle("Live Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
    }

    private var statusBanner: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(viewModel.isConnected ? .green : .orange)
                .frame(width: 10, height: 10)
            Text(viewModel.status?.rawValue.replacingOccurrences(of: "_", with: " ").capitalized ?? "Connecting")
                .font(.subheadline.weight(.semibold))
            Spacer()
            if !viewModel.isConnected {
                ProgressView()
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
