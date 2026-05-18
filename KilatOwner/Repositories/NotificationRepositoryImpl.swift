import Foundation

struct NotificationRepositoryImpl: NotificationRepository {
    typealias NowProvider = () -> Date

    private let client: APIClient
    private let nowProvider: NowProvider

    init(
        client: APIClient,
        nowProvider: @escaping NowProvider = Date.init
    ) {
        self.client = client
        self.nowProvider = nowProvider
    }

    func list(cursor: String?, limit: Int) async throws -> NotificationListDTO {
        try await client.get(Endpoints.Notifications.list(cursor: cursor, limit: limit))
    }

    func markRead(id: String) async throws {
        let request = MarkNotificationReadRequest(readAt: nowProvider())
        let _: EmptyResponse = try await client.post(Endpoints.Notifications.markRead(id: id), body: request)
    }
}

private struct MarkNotificationReadRequest: Encodable {
    let readAt: Date

    enum CodingKeys: String, CodingKey {
        case readAt = "read_at"
    }
}
