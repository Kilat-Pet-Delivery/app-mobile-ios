import SwiftUI
import KilatUI

struct NotificationsView: View {
    @Bindable var viewModel: NotificationsViewModel

    var body: some View {
        Group {
            if viewModel.isLoadingInitial {
                loadingView
            } else if viewModel.showsEmptyState {
                emptyView
            } else {
                notificationList
            }
        }
        .navigationTitle("Notifications")
        .background(Tokens.Color.background.ignoresSafeArea())
        .task {
            await viewModel.loadIfNeeded()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    private var notificationList: some View {
        List {
            ForEach(viewModel.sections) { section in
                Section {
                    ForEach(section.notifications) { notification in
                        Button {
                            Task {
                                await viewModel.notificationTapped(notification)
                            }
                        } label: {
                            NotificationRow(
                                notification: notification,
                                relativeTimestamp: viewModel.relativeTimestamp(for: notification)
                            )
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Tokens.Color.surface)
                        .task {
                            await viewModel.loadNextPageIfNeeded(currentItem: notification)
                        }
                    }
                } header: {
                    Text(section.title)
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.textSecondary)
                }
            }

            if viewModel.isLoadingNextPage {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(Tokens.Color.primary)
                    Spacer()
                }
                .listRowBackground(Tokens.Color.surface)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private var loadingView: some View {
        VStack(spacing: Tokens.Space.md) {
            ProgressView()
                .tint(Tokens.Color.primary)

            Text("Loading notifications")
                .font(Tokens.FontRole.caption)
                .foregroundStyle(Tokens.Color.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: Tokens.Space.md) {
            ZStack {
                Circle()
                    .fill(Tokens.Color.primaryTonal)

                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Tokens.Color.onPrimaryTonal)
            }
            .frame(width: 72, height: 72)

            VStack(spacing: Tokens.Space.xs) {
                Text("No notifications")
                    .font(Tokens.FontRole.titleL)
                    .foregroundStyle(Tokens.Color.textPrimary)

                Text("Booking updates and runner messages will appear here.")
                    .font(Tokens.FontRole.body)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Tokens.Space.xl)
        .frame(maxWidth: 360)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        NotificationsView(
            viewModel: NotificationsViewModel(
                notificationRepository: StubNotificationRepository(),
                initialNotifications: SampleData.notifications,
                nowProvider: { SampleData.baseDate.addingTimeInterval(3_600) }
            )
        )
    }
}
