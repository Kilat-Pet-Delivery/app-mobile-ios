import Foundation

protocol NotificationRepository {
    func list(cursor: String?, limit: Int) async throws -> NotificationListDTO
    func markRead(id: String) async throws
}
