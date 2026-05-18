import Foundation

protocol PetRepository {
    func listMyPets() async throws -> [PetDTO]
    func createPet(_ request: CreatePetRequest) async throws -> PetDTO
}
