import SwiftUI

struct RegisterView: View {
    @Bindable private var viewModel: RegisterViewModel
    private let onLogin: () -> Void

    init(viewModel: RegisterViewModel, onLogin: @escaping () -> Void = {}) {
        self.viewModel = viewModel
        self.onLogin = onLogin
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Text("Create Account")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)

                    field("First name", text: $viewModel.firstName, key: "firstName")
                    field("Last name", text: $viewModel.lastName, key: "lastName")
                    field("Phone", text: $viewModel.phone, key: "phone", keyboard: .phonePad)
                    field("Email", text: $viewModel.email, key: "email", keyboard: .emailAddress)

                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.newPassword)
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    validationText(for: "password")

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task { await viewModel.register() }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(viewModel.isLoading ? "Creating Account" : "Create Account")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(viewModel.isLoading)

                    Button("Already have an account? Sign in") {
                        onLogin()
                    }
                    .buttonStyle(.plain)
                }
                .padding(24)
            }
        }
    }

    private func field(
        _ title: String,
        text: Binding<String>,
        key: String,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(spacing: 6) {
            TextField(title, text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(key == "email" ? .never : .words)
                .autocorrectionDisabled(key == "email")
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
            validationText(for: key)
        }
    }

    @ViewBuilder
    private func validationText(for key: String) -> some View {
        if let error = viewModel.fieldErrors[key] {
            Text(error)
                .font(.footnote)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    RegisterView(viewModel: RegisterViewModel(appSession: AppSession()))
}
