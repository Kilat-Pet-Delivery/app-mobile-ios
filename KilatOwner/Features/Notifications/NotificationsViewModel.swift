import Foundation
import Observation

enum NotificationDayBucket: Equatable, Sendable {
    case today
    case yesterday
    case thisWeek
    case older

    var title: String {
        switch self {
        case .today:
            return "Today"
        case .yesterday:
            return "Yesterday"
        case .thisWeek:
            return "This week"
        case .older:
            return "Older"
        }
    }
}

struct NotificationSectionModel: Equatable, Identifiable, Sendable {
    let bucket: NotificationDayBucket
    let notifications: [NotificationDTO]

    var id: String {
        bucket.title
    }

    var title: String {
        bucket.title
    }
}

@MainActor
@Observable
final class NotificationsViewModel {
    var notifications: [NotificationDTO]
    var isLoadingInitial: Bool
    var isRefreshing: Bool
    var isLoadingNextPage: Bool
    var errorMessage: String?

    let pageSize: Int

    private let notificationRepository: NotificationRepository
    private let coordinator: RootCoordinator?
    private let nowProvider: () -> Date
    private let bookingIDResolver: (NotificationDTO) -> String
    private let calendar: Calendar
    private var nextCursor: String
    private var hasLoaded: Bool

    init(
        notificationRepository: NotificationRepository,
        coordinator: RootCoordinator? = nil,
        pageSize: Int = 20,
        initialNotifications: [NotificationDTO]? = nil,
        initialNextCursor: String = "",
        nowProvider: @escaping () -> Date = { Date() },
        bookingIDResolver: @escaping (NotificationDTO) -> String = { _ in SampleData.activeBookingID.uuidString },
        calendar: Calendar = .kilatUTC
    ) {
        self.notificationRepository = notificationRepository
        self.coordinator = coordinator
        self.pageSize = pageSize
        self.notifications = initialNotifications ?? []
        self.nextCursor = initialNextCursor
        self.nowProvider = nowProvider
        self.bookingIDResolver = bookingIDResolver
        self.calendar = calendar
        self.isLoadingInitial = false
        self.isRefreshing = false
        self.isLoadingNextPage = false
        self.hasLoaded = initialNotifications != nil
    }

    var sections: [NotificationSectionModel] {
        Self.groupByDay(notifications, now: nowProvider(), calendar: calendar)
    }

    var showsEmptyState: Bool {
        !isLoadingInitial && notifications.isEmpty
    }

    var hasMorePages: Bool {
        !nextCursor.isEmpty
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await loadInitial()
    }

    func loadInitial() async {
        isLoadingInitial = true
        errorMessage = nil
        defer {
            isLoadingInitial = false
            hasLoaded = true
        }

        await loadFirstPage()
    }

    func refresh() async {
        isRefreshing = true
        errorMessage = nil
        defer {
            isRefreshing = false
            hasLoaded = true
        }

        await loadFirstPage()
    }

    func loadNextPageIfNeeded(currentItem: NotificationDTO? = nil) async {
        guard hasMorePages, !isLoadingNextPage else { return }

        if let currentItem, currentItem.id != notifications.last?.id {
            return
        }

        isLoadingNextPage = true
        errorMessage = nil
        defer {
            isLoadingNextPage = false
        }

        do {
            let page = try await notificationRepository.list(cursor: nextCursor, limit: pageSize)
            notifications.append(contentsOf: page.items)
            nextCursor = page.nextCursor
        } catch {
            errorMessage = userMessage(for: error)
        }
    }

    func notificationTapped(_ notification: NotificationDTO) async {
        do {
            try await notificationRepository.markRead(id: notification.id)
            markLocalRead(notification)
            route(for: notification)
        } catch {
            errorMessage = userMessage(for: error)
        }
    }

    func relativeTimestamp(for notification: NotificationDTO) -> String {
        let elapsedSeconds = max(0, Int(nowProvider().timeIntervalSince(notification.createdAt)))

        if elapsedSeconds < 60 {
            return "Now"
        }

        let elapsedMinutes = elapsedSeconds / 60
        if elapsedMinutes < 60 {
            return "\(elapsedMinutes)m ago"
        }

        let elapsedHours = elapsedMinutes / 60
        if elapsedHours < 24 {
            return "\(elapsedHours)h ago"
        }

        let elapsedDays = elapsedHours / 24
        if elapsedDays == 1 {
            return "Yesterday"
        }

        return "\(elapsedDays)d ago"
    }

    static func groupByDay(
        _ notifications: [NotificationDTO],
        now: Date,
        calendar: Calendar = .kilatUTC
    ) -> [NotificationSectionModel] {
        let sorted = notifications.sorted { lhs, rhs in
            lhs.createdAt > rhs.createdAt
        }
        let buckets: [NotificationDayBucket] = [.today, .yesterday, .thisWeek, .older]

        return buckets.compactMap { bucket in
            let items = sorted.filter {
                bucketFor($0.createdAt, now: now, calendar: calendar) == bucket
            }

            guard !items.isEmpty else { return nil }
            return NotificationSectionModel(bucket: bucket, notifications: items)
        }
    }

    private func loadFirstPage() async {
        do {
            let page = try await notificationRepository.list(cursor: nil, limit: pageSize)
            notifications = page.items
            nextCursor = page.nextCursor
        } catch {
            errorMessage = userMessage(for: error)
        }
    }

    private func markLocalRead(_ notification: NotificationDTO) {
        guard let index = notifications.firstIndex(where: { $0.id == notification.id }) else { return }
        let original = notifications[index]
        notifications[index] = NotificationDTO(
            id: original.id,
            type: original.type,
            title: original.title,
            body: original.body,
            createdAt: original.createdAt,
            readAt: nowProvider()
        )
    }

    private func route(for notification: NotificationDTO) {
        let bookingID = bookingIDResolver(notification)

        switch notification.type {
        case .runnerAssigned:
            coordinator?.push(.bookingConfirmed(bookingID: bookingID))
        case .chatMessage, .trackingUpdated:
            coordinator?.push(.tracking(bookingID: bookingID))
        case .bookingStatusChanged,
             .bookingAccepted,
             .bookingCompleted,
             .bookingCancelled,
             .paymentEscrowHeld,
             .paymentFailed,
             .unknown:
            coordinator?.push(.bookingDetail(bookingID: bookingID))
        }
    }

    private static func bucketFor(
        _ date: Date,
        now: Date,
        calendar: Calendar
    ) -> NotificationDayBucket {
        if calendar.isDate(date, inSameDayAs: now) {
            return .today
        }

        if
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
            calendar.isDate(date, inSameDayAs: yesterday)
        {
            return .yesterday
        }

        if
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now),
            date >= sevenDaysAgo
        {
            return .thisWeek
        }

        return .older
    }

    private func userMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.userMessage
        }

        if error is URLError {
            return "Unable to load notifications. Check your connection and try again."
        }

        return "Unable to load notifications. Please try again."
    }
}

private extension Calendar {
    static var kilatUTC: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }
}
