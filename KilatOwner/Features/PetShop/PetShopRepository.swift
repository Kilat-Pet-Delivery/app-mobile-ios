import Foundation

protocol PetShopRepositoryProtocol {
    func list(page: Int, query: String?) async throws -> [PetShop]
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

    func list(page: Int = 1, query: String? = nil) async throws -> [PetShop] {
        let envelope: APIResponseEnvelope<[PetShop]> = try await authInterceptor.perform(
            .petshopsList(page: page, query: query)
        )
        return envelope.data
    }

    func detail(id: String) async throws -> PetShop {
        let envelope: APIResponseEnvelope<PetShop> = try await authInterceptor.perform(.petshopDetail(id: id))
        return envelope.data
    }
}
