import SwiftUI

struct PetShopListView: View {
    @Bindable private var viewModel: PetShopListViewModel

    init(viewModel: PetShopListViewModel = PetShopListViewModel()) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if viewModel.shops.isEmpty {
                ContentUnavailableView("No pet shops found", systemImage: "storefront")
            } else {
                ForEach(viewModel.shops) { shop in
                    NavigationLink {
                        PetShopDetailView(
                            viewModel: PetShopDetailViewModel(shopId: shop.id)
                        )
                    } label: {
                        PetShopRow(shop: shop)
                    }
                }
            }
        }
        .navigationTitle("Pet Shops")
        .searchable(text: $viewModel.searchText)
        .refreshable {
            await viewModel.reload()
        }
        .task {
            await viewModel.onAppear()
        }
    }
}

private struct PetShopRow: View {
    let shop: PetShop

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(shop.name)
                    .font(.headline)
                Spacer()
                Label(String(format: "%.1f", shop.rating), systemImage: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Text(shop.address)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Text(shop.categoryDisplay)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.blue.opacity(0.12), in: Capsule())
                .foregroundStyle(.blue)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    NavigationStack {
        PetShopListView()
    }
}
