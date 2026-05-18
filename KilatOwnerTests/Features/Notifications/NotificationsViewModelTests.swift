import XCTest
@testable import KilatOwner

@MainActor
final class NotificationsViewModelTests: XCTestCase {
    func testNotificationsVM_initialLoad_fetchesFirstPage() async {
        let repository = NotificationsRepositoryDouble(pages: [
            NotificationListDTO(items: [Self.notification(id: "today")], nextCursor: "cursor-2")
        ])
        let viewModel = makeViewModel(repository: repository)

        await viewModel.loadIfNeeded()

        XCTAssertEqual(repository.listCalls, [ListCall(cursor: nil, limit: 2)])
        XCTAssertEqual(viewModel.notifications.map(\.id), ["today"])
        XCTAssertTrue(viewModel.hasMorePages)
    }

    func testNotificationsVM_pullRefresh_resetsCursor_reloadsFromTop() async {
        let repository = NotificationsRepositoryDouble(pages: [
            NotificationListDTO(items: [Self.notification(id: "first")], nextCursor: "cursor-2"),
            NotificationListDTO(items: [Self.notification(id: "second")], nextCursor: "")
        ])
        let viewModel = makeViewModel(repository: repository)
        await viewModel.loadIfNeeded()

        await viewModel.refresh()

        XCTAssertEqual(repository.listCalls, [
            ListCall(cursor: nil, limit: 2),
            ListCall(cursor: nil, limit: 2)
        ])
        XCTAssertEqual(viewModel.notifications.map(\.id), ["second"])
        XCTAssertFalse(viewModel.hasMorePages)
    }

    func testNotificationsVM_scrollToEnd_loadsNextPage() async {
        let first = Self.notification(id: "first")
        let second = Self.notification(id: "second")
        let repository = NotificationsRepositoryDouble(pages: [
            NotificationListDTO(items: [first], nextCursor: "cursor-2"),
            NotificationListDTO(items: [second], nextCursor: "")
        ])
        let viewModel = makeViewModel(repository: repository)
        await viewModel.loadIfNeeded()

        await viewModel.loadNextPageIfNeeded(currentItem: first)

        XCTAssertEqual(repository.listCalls, [
            ListCall(cursor: nil, limit: 2),
            ListCall(cursor: "cursor-2", limit: 2)
        ])
        XCTAssertEqual(viewModel.notifications.map(\.id), ["first", "second"])
    }

    func testNotificationsVM_tapNotification_marksReadAndRoutes_byKind() async {
        let coordinator = RootCoordinator()
        let booking = Self.notification(id: "booking", type: .bookingStatusChanged)
        let runner = Self.notification(id: "runner", type: .runnerAssigned)
        let chat = Self.notification(id: "chat", type: .chatMessage)
        let repository = NotificationsRepositoryDouble(pages: [
            NotificationListDTO(items: [booking, runner, chat], nextCursor: "")
        ])
        let viewModel = makeViewModel(repository: repository, coordinator: coordinator)
        await viewModel.loadIfNeeded()

        await viewModel.notificationTapped(booking)
        await viewModel.notificationTapped(runner)
        await viewModel.notificationTapped(chat)

        XCTAssertEqual(repository.markReadCalls, ["booking", "runner", "chat"])
        XCTAssertEqual(coordinator.path, [
            .bookingDetail(bookingID: SampleData.activeBookingID.uuidString),
            .bookingConfirmed(bookingID: SampleData.activeBookingID.uuidString),
            .tracking(bookingID: SampleData.activeBookingID.uuidString)
        ])
        XCTAssertTrue(viewModel.notifications.allSatisfy { $0.readAt != nil })
    }

    func testNotificationsVM_groupByDay_returnsCorrectSectionForToday_yesterday_thisWeek_older() {
        let now = SampleData.baseDate.addingTimeInterval(12 * 3_600)
        let grouped = NotificationsViewModel.groupByDay([
            Self.notification(id: "older", createdAt: now.addingTimeInterval(-10 * 86_400)),
            Self.notification(id: "week", createdAt: now.addingTimeInterval(-3 * 86_400)),
            Self.notification(id: "yesterday", createdAt: now.addingTimeInterval(-86_400)),
            Self.notification(id: "today", createdAt: now.addingTimeInterval(-600))
        ], now: now)

        XCTAssertEqual(grouped.map(\.bucket), [.today, .yesterday, .thisWeek, .older])
        XCTAssertEqual(grouped.map { $0.notifications.map(\.id) }, [["today"], ["yesterday"], ["week"], ["older"]])
    }

    func testNotificationsVM_emptyState_showsEmptyStateView() async {
        let repository = NotificationsRepositoryDouble(pages: [
            NotificationListDTO(items: [], nextCursor: "")
        ])
        let viewModel = makeViewModel(repository: repository)

        await viewModel.loadIfNeeded()

        XCTAssertTrue(viewModel.showsEmptyState)
        XCTAssertFalse(viewModel.isLoadingInitial)
    }

    static func notification(
        id: String,
        type: NotificationKind = .bookingStatusChanged,
        title: String = "Booking update",
        body: String = "Mochi's trip status changed.",
        createdAt: Date = SampleData.baseDate,
        readAt: Date? = nil
    ) -> NotificationDTO {
        NotificationDTO(
            id: id,
            type: type,
            title: title,
            body: body,
            createdAt: createdAt,
            readAt: readAt
        )
    }

    private func makeViewModel(
        repository: NotificationsRepositoryDouble,
        coordinator: RootCoordinator? = nil
    ) -> NotificationsViewModel {
        NotificationsViewModel(
            notificationRepository: repository,
            coordinator: coordinator,
            pageSize: 2,
            nowProvider: { SampleData.baseDate.addingTimeInterval(12 * 3_600) }
        )
    }
}

private struct ListCall: Equatable {
    let cursor: String?
    let limit: Int
}

private final class NotificationsRepositoryDouble: NotificationRepository {
    private(set) var listCalls: [ListCall] = []
    private(set) var markReadCalls: [String] = []
    private var pages: [NotificationListDTO]

    init(pages: [NotificationListDTO]) {
        self.pages = pages
    }

    func list(cursor: String?, limit: Int) async throws -> NotificationListDTO {
        listCalls.append(ListCall(cursor: cursor, limit: limit))

        if pages.isEmpty {
            return NotificationListDTO(items: [], nextCursor: "")
        }

        return pages.removeFirst()
    }

    func markRead(id: String) async throws {
        markReadCalls.append(id)
    }
}
