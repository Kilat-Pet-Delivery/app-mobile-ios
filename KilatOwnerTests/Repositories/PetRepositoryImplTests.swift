import XCTest
@testable import KilatOwner

final class PetRepositoryImplTests: XCTestCase {
    private var tokenStore: InMemoryTokenStore!
    private var client: APIClient!
    private var repository: PetRepositoryImpl!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)

        tokenStore = InMemoryTokenStore()
        client = APIClient(
            baseURL: URL(string: "https://example.test")!,
            session: session,
            tokenStore: tokenStore
        )
        repository = PetRepositoryImpl(client: client)
    }

    override func tearDown() {
        repository = nil
        client = nil
        tokenStore = nil
        MockURLProtocol.reset()
        super.tearDown()
    }

    func testPetRepoImpl_listMyPets_decodesArray() async throws {
        try tokenStore.saveAccessToken("access-token")

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/api/v1/users/me/pets")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer access-token")

            return try Self.jsonResponse(request: request, value: [SampleData.mochiPet, SampleData.baoPet])
        }

        let pets = try await repository.listMyPets()

        XCTAssertEqual(pets.map(\.id), [SampleData.mochiID, SampleData.baoID])
    }

    func testPetRepoImpl_createPet_postsCorrectShape_returnsCreatedPet() async throws {
        try tokenStore.saveAccessToken("access-token")

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/api/v1/users/me/pets")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer access-token")

            let body = try Self.jsonBody(from: request)
            XCTAssertEqual(body["name"] as? String, "Taro")
            XCTAssertEqual(body["pet_type"] as? String, "dog")
            XCTAssertEqual(body["breed"] as? String, "Shiba Inu")
            let weightKg = try XCTUnwrap(body["weight_kg"] as? Double)
            XCTAssertEqual(weightKg, 9.4, accuracy: 0.001)
            XCTAssertEqual(body["age_months"] as? Int, 28)
            XCTAssertEqual(body["allergies"] as? String, "Chicken")
            XCTAssertEqual(body["special_needs"] as? String, "Harness only")
            XCTAssertEqual(body["notes"] as? String, "Gets carsick")
            XCTAssertEqual(body["photo_url"] as? String, "https://cdn.kilat.test/taro.png")
            XCTAssertEqual(body["vaccination_status"] as? String, "verified")

            let createdPet = PetDTO(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000103")!,
                ownerID: SampleData.ownerID,
                name: "Taro",
                petType: .dog,
                breed: "Shiba Inu",
                weightKg: 9.4,
                ageMonths: 28,
                allergies: "Chicken",
                specialNeeds: "Harness only",
                notes: "Gets carsick",
                photoURL: "https://cdn.kilat.test/taro.png",
                vaccinationStatus: "verified",
                status: "active",
                createdAt: SampleData.baseDate,
                updatedAt: SampleData.baseDate
            )
            return try Self.jsonResponse(request: request, value: createdPet)
        }

        let request = CreatePetRequest(
            name: "Taro",
            petType: .dog,
            breed: "Shiba Inu",
            weightKg: 9.4,
            ageMonths: 28,
            allergies: "Chicken",
            specialNeeds: "Harness only",
            notes: "Gets carsick",
            photoURL: "https://cdn.kilat.test/taro.png",
            vaccinationStatus: "verified"
        )

        let createdPet = try await repository.createPet(request)

        XCTAssertEqual(createdPet.name, "Taro")
        XCTAssertEqual(createdPet.petType, .dog)
        XCTAssertEqual(createdPet.id.uuidString, "00000000-0000-0000-0000-000000000103")
    }

    private static func jsonBody(from request: URLRequest) throws -> [String: Any] {
        let data = try XCTUnwrap(request.httpBody)
        let object = try JSONSerialization.jsonObject(with: data)
        return try XCTUnwrap(object as? [String: Any])
    }

    private static func jsonResponse<T: Encodable>(
        request: URLRequest,
        value: T
    ) throws -> (HTTPURLResponse, Data?) {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (response, try envelopeData(for: value))
    }

    private static func envelopeData<T: Encodable>(for value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        var data = Data(#"{"success":true,"data":"#.utf8)
        data.append(try encoder.encode(value))
        data.append(Data("}".utf8))
        return data
    }
}
