import SwiftUI
import XCTest
@testable import KilatOwner

@MainActor
final class NotificationsViewSnapshotTests: XCTestCase {
    func testNotificationsView_empty() throws {
        try assertAuthSnapshot(
            NavigationStack {
                NotificationsView(
                    viewModel: viewModel(initialNotifications: [])
                )
            },
            named: "testNotificationsView_empty",
            size: CGSize(width: 393, height: 852)
        )
    }

    func testNotificationsView_populated_groupedByDay() throws {
        try assertAuthSnapshot(
            NavigationStack {
                NotificationsView(
                    viewModel: viewModel(initialNotifications: Self.groupedNotifications())
                )
            },
            named: "testNotificationsView_populated_groupedByDay",
            size: CGSize(width: 393, height: 852)
        )
    }

    func testNotificationsView_loadingNextPage() throws {
        let viewModel = viewModel(
            initialNotifications: Self.groupedNotifications(),
            initialNextCursor: "cursor-2"
        )
        viewModel.isLoadingNextPage = true

        try assertAuthSnapshot(
            NavigationStack {
                NotificationsView(viewModel: viewModel)
            },
            named: "testNotificationsView_loadingNextPage",
            size: CGSize(width: 393, height: 852)
        )
    }

    static func groupedNotifications() -> [NotificationDTO] {
        let now = SampleData.baseDate.addingTimeInterval(12 * 3_600)
        return [
            NotificationsViewModelTests.notification(
                id: "today",
                type: .runnerAssigned,
                title: "Runner assigned",
                body: "Aiman is on the way for Mochi.",
                createdAt: now.addingTimeInterval(-1_200)
            ),
            NotificationsViewModelTests.notification(
                id: "yesterday",
                type: .paymentEscrowHeld,
                title: "Payment authorized",
                body: "RM18.00 is held safely until delivery.",
                createdAt: now.addingTimeInterval(-86_400),
                readAt: now.addingTimeInterval(-80_000)
            ),
            NotificationsViewModelTests.notification(
                id: "week",
                type: .chatMessage,
                title: "New message",
                body: "Aiman shared a quick update from the pickup point.",
                createdAt: now.addingTimeInterval(-3 * 86_400)
            )
        ]
    }

    private func viewModel(
        initialNotifications: [NotificationDTO],
        initialNextCursor: String = ""
    ) -> NotificationsViewModel {
        NotificationsViewModel(
            notificationRepository: SnapshotNotificationRepository(),
            initialNotifications: initialNotifications,
            initialNextCursor: initialNextCursor,
            nowProvider: { SampleData.baseDate.addingTimeInterval(12 * 3_600) }
        )
    }
}

private struct SnapshotNotificationRepository: NotificationRepository {
    func list(cursor: String?, limit: Int) async throws -> NotificationListDTO {
        NotificationListDTO(items: [], nextCursor: "")
    }

    func markRead(id: String) async throws {}
}
