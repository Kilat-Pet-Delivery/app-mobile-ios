import SwiftUI

struct PetShopDetailView: View {
    @Bindable private var viewModel: PetShopDetailViewModel

    init(viewModel: PetShopDetailViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if let shop = viewModel.shop {
                    header(shop)
                    serviceList
                    NavigationLink("Book Delivery") {
                        Text("Booking Create coming Phase 5.")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else if let errorMessage = viewModel.errorMessage {
                    ContentUnavailableView(
                        "Could not load pet shop",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                }
            }
            .padding(20)
        }
        .navigationTitle(viewModel.shop?.name ?? "Pet Shop")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.onAppear()
        }
    }

    private func header(_ shop: PetShop) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(shop.name)
                .font(.largeTitle.bold())
            Text(shop.description ?? shop.categoryDisplay)
                .foregroundStyle(.secondary)
            Label(shop.address, systemImage: "mappin.and.ellipse")
                .font(.subheadline)
            if !shop.phone.isEmpty {
                Label(shop.phone, systemImage: "phone.fill")
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var serviceList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Services")
                .font(.headline)

            if viewModel.services.isEmpty {
                Text("No listed services yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.services) { service in
                    HStack {
                        Image(systemName: "pawprint.fill")
                            .foregroundStyle(.blue)
                        Text(service.name)
                        Spacer()
                    }
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PetShopDetailView(viewModel: PetShopDetailViewModel(shopId: "preview"))
    }
}
