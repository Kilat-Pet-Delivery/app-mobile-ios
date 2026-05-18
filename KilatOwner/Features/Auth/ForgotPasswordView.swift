import SwiftUI
import KilatUI

struct ForgotPasswordView: View {
    @Bindable var viewModel: ForgotPasswordViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.xl) {
                header
                form
            }
            .padding(.horizontal, Tokens.Space.lg)
            .padding(.vertical, Tokens.Space.xxl)
            .frame(maxWidth: 430)
            .frame(maxWidth: .infinity)
        }
        .background(Tokens.Color.background.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            ZStack {
                Circle()
                    .fill(Tokens.Color.primaryTonal)
                Image(systemName: "key.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Tokens.Color.onPrimaryTonal)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                Text("Reset your password")
                    .font(Tokens.FontRole.displayL)
                    .foregroundStyle(Tokens.Color.textPrimary)

                Text("Enter your account email and we will send a secure reset link.")
                    .font(Tokens.FontRole.body)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var form: some View {
        Card {
            VStack(alignment: .leading, spacing: Tokens.Space.md) {
                if let validationError = viewModel.validationError {
                    messageBanner(validationError, systemImage: "exclamationmark.circle.fill")
                }

                if let errorMessage = viewModel.errorMessage {
                    messageBanner(errorMessage, systemImage: "wifi.exclamationmark")
                }

                Text("Email")
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)

                TextField("you@example.com", text: $viewModel.email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .forgotPasswordTextFieldStyle()

                PrimaryButton(
                    title: "Send reset link",
                    icon: "paperplane.fill",
                    isLoading: viewModel.isLoading
                ) {
                    Task { await viewModel.submit() }
                }
            }
        }
    }

    private func messageBanner(_ text: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: Tokens.Space.xs) {
            Image(systemName: systemImage)
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

private extension View {
    func forgotPasswordTextFieldStyle() -> some View {
        self
            .font(Tokens.FontRole.body)
            .foregroundStyle(Tokens.Color.textPrimary)
            .padding(.horizontal, Tokens.Space.md)
            .frame(height: 52)
            .background(Tokens.Color.surfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous)
                    .stroke(Tokens.Color.separator, lineWidth: 1)
            )
    }
}

#Preview {
    ForgotPasswordView(
        viewModel: ForgotPasswordViewModel(
            email: "owner@kilat.my",
            authRepository: StubAuthRepository()
        )
    )
}
