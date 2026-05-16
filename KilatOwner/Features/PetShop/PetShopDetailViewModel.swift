import Foundation
import Observation

@Observable
final class PetShopDetailViewModel {
    let shopId: String
    private(set) var shop: PetShop?
    private(set) var isLoading = false
    var errorMessage: String?

    var services: [PetShopService] {
        shop?.serviceModels ?? []
    }

    @ObservationIgnored private let repository: PetShopRepositoryProtocol

    init(shopId: String, repository: PetShopRepositoryProtocol = PetShopRepository()) {
        self.shopId = shopId
        self.repository = repository
    }

    @MainActor
    func onAppear() async {
        guard shop == nil else {
            return
        }
        await load()
    }

    @MainActor
    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            shop = try await repository.detail(id: shopId)
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }
}
