import Foundation

protocol PetShopRepositoryProtocol {
    // Backend `GET /api/v1/petshops` returns all shops (optionally filtered by category).
    // No server-side pagination — list view filters locally.
    func list(category: String?) async throws -> [PetShop]
    func detail(id: String) async throws -> PetShop
}

final class PetShopRepository: PetShopRepositoryProtocol {
    private let authInterceptor: AuthInterceptor

    init(authInterceptor: AuthInterceptor) {
        self.authInterceptor = authInterceptor
    }

    convenience init(apiClient: APIClient = APIClient(), tokenStore: TokenStore = KeychainStore()) {
        self.init(authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore))
    }

    func list(category: String? = nil) async throws -> [PetShop] {
        let envelope: APIResponseEnvelope<[PetShop]> = try await authInterceptor.perform(
            .petshopsList(category: category)
        )
        return envelope.data
    }

    func detail(id: String) async throws -> PetShop {
        let envelope: APIResponseEnvelope<PetShop> = try await authInterceptor.perform(.petshopDetail(id: id))
        return envelope.data
    }
}
