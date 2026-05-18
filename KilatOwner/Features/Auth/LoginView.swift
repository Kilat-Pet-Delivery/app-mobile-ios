import SwiftUI
import KilatUI

struct LoginView: View {
    @Bindable var viewModel: LoginViewModel

    private let applyURL = URL(string: "https://kilat.example.com/runner/apply")!

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.xl) {
                header
                form
                footerActions
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
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Tokens.Color.onPrimaryTonal)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                Text("Welcome back")
                    .font(Tokens.FontRole.displayL)
                    .foregroundStyle(Tokens.Color.textPrimary)

                Text("Sign in to book care, track runners, and manage your pet trips.")
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

                fieldLabel("Email")
                TextField("you@example.com", text: $viewModel.email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .formTextFieldStyle()

                fieldLabel("Password")
                SecureField("Password", text: $viewModel.password)
                    .textInputAutocapitalization(.never)
                    .formTextFieldStyle()

                PrimaryButton(
                    title: "Sign in",
                    icon: "arrow.right",
                    isLoading: viewModel.isLoading
                ) {
                    Task { await viewModel.submit() }
                }
            }
        }
    }

    private var footerActions: some View {
        VStack(spacing: Tokens.Space.sm) {
            SecondaryButton(title: "Forgot password?", icon: "key") {
                viewModel.forgotPasswordTapped()
            }

            Link(destination: applyURL) {
                HStack(spacing: Tokens.Space.xs) {
                    Image(systemName: "figure.run")
                    Text("Apply to be a runner")
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Tokens.Space.xs)
            }
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(Tokens.FontRole.caption)
            .foregroundStyle(Tokens.Color.textSecondary)
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
    func formTextFieldStyle() -> some View {
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
    LoginView(
        viewModel: LoginViewModel(
            email: "owner@kilat.my",
            authRepository: StubAuthRepository()
        )
    )
}
