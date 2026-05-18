import SwiftUI
import KilatUI

struct CancelReasonSheet: View {
    @State private var viewModel: CancelReasonViewModel
    private let onKeepBooking: () -> Void

    init(
        viewModel: CancelReasonViewModel,
        onKeepBooking: @escaping () -> Void = {}
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onKeepBooking = onKeepBooking
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.lg) {
                grabber
                header

                Card {
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.reasons.enumerated()), id: \.element.id) { index, reason in
                            Button {
                                viewModel.selectReason(reason)
                            } label: {
                                CancelReasonRow(
                                    title: reason.label,
                                    isSelected: viewModel.selectedReason == reason
                                )
                            }
                            .buttonStyle(.plain)

                            if index < viewModel.reasons.count - 1 {
                                Divider()
                                    .background(Tokens.Color.separator)
                            }
                        }
                    }
                }

                if viewModel.showsFreeTextField {
                    freeTextField(text: $viewModel.freeText)
                }

                if let errorMessage = viewModel.errorMessage {
                    messageBanner(errorMessage)
                }

                VStack(spacing: Tokens.Space.sm) {
                    PrimaryButton(
                        title: "Cancel booking",
                        icon: "xmark.circle.fill",
                        isLoading: viewModel.isSubmitting,
                        isEnabled: viewModel.isSubmitEnabled
                    ) {
                        Task {
                            await viewModel.submit()
                        }
                    }

                    SecondaryButton(title: "Keep booking", icon: "arrow.uturn.backward") {
                        onKeepBooking()
                    }
                }
            }
            .padding(.horizontal, Tokens.Space.lg)
            .padding(.top, Tokens.Space.md)
            .padding(.bottom, Tokens.Space.xxl)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Tokens.Color.background.ignoresSafeArea())
    }

    private var grabber: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(Tokens.Color.separator)
            .frame(width: 42, height: 4)
            .frame(maxWidth: .infinity)
            .padding(.bottom, Tokens.Space.xs)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            Text("Cancel booking")
                .font(Tokens.FontRole.titleL)
                .foregroundStyle(Tokens.Color.textPrimary)

            Text("Choose a reason so the runner and support team get the right context.")
                .font(Tokens.FontRole.body)
                .foregroundStyle(Tokens.Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func freeTextField(text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            Text("Tell us more")
                .font(Tokens.FontRole.caption)
                .foregroundStyle(Tokens.Color.textSecondary)

            TextEditor(text: text)
                .font(Tokens.FontRole.body)
                .foregroundStyle(Tokens.Color.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 92)
                .padding(Tokens.Space.sm)
                .background(Tokens.Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous)
                        .stroke(Tokens.Color.separator, lineWidth: 1)
                )
        }
    }

    private func messageBanner(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Tokens.Space.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16, weight: .semibold))
                .padding(.top, 1)

            Text(text)
                .font(Tokens.FontRole.caption)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(Tokens.Color.destructive)
        .padding(Tokens.Space.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous)
                .fill(Tokens.Color.destructive.opacity(0.10))
        )
    }
}

private struct CancelReasonRow: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: Tokens.Space.sm) {
            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(isSelected ? Tokens.Color.primary : Tokens.Color.textSecondary)
                .frame(width: 28)

            Text(title)
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: Tokens.Space.sm)
        }
        .padding(.vertical, Tokens.Space.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

#Preview {
    CancelReasonSheet(
        viewModel: CancelReasonViewModel(
            bookingID: SampleData.activeBookingID.uuidString,
            bookingRepository: StubBookingRepository()
        )
    )
}
