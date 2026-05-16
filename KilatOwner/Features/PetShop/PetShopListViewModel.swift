import Foundation
import Observation

@Observable
final class PetShopListViewModel {
    private(set) var allShops: [PetShop] = []
    private(set) var isLoading = false
    var errorMessage: String?
    var searchText = ""

    @ObservationIgnored private let repository: PetShopRepositoryProtocol

    init(repository: PetShopRepositoryProtocol = PetShopRepository()) {
        self.repository = repository
    }

    // Backend returns all pet shops in a single list (no server-side pagination today).
    // Search is in-memory across name/address/category.
    var shops: [PetShop] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else {
            return allShops
        }
        return allShops.filter { shop in
            shop.name.lowercased().contains(trimmed)
                || shop.address.lowercased().contains(trimmed)
                || shop.category.lowercased().contains(trimmed)
        }
    }

    @MainActor
    func onAppear() async {
        guard allShops.isEmpty else {
            return
        }
        await reload()
    }

    @MainActor
    func reload() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            allShops = try await repository.list(category: nil)
        } catch {
            allShops = []
            errorMessage = message(for: error)
        }
    }

    private func message(for error: Error) -> String {
        if let networkError = error as? NetworkError {
            return networkError.userMessage
        }
        return NetworkError.unknown(error.localizedDescription).userMessage
    }
}
