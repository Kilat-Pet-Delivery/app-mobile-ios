import Foundation

struct PetRepositoryImpl: PetRepository {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func listMyPets() async throws -> [PetDTO] {
        try await client.get(Endpoints.Pets.mine)
    }

    func createPet(_ request: CreatePetRequest) async throws -> PetDTO {
        try await client.post(Endpoints.Pets.create, body: request)
    }
}
