import SwiftUI
import KilatUI

struct SignupView: View {
    @Bindable var viewModel: SignupViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.lg) {
                header
                banners
                ownerCard
                petCard
                submitButton
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
                Image(systemName: "sparkles")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Tokens.Color.onPrimaryTonal)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                Text("Create your account")
                    .font(Tokens.FontRole.displayL)
                    .foregroundStyle(Tokens.Color.textPrimary)

                Text("Add your details and your first pet so booking feels ready from day one.")
                    .font(Tokens.FontRole.body)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var banners: some View {
        if let validationError = viewModel.validationError {
            messageBanner(validationError, systemImage: "exclamationmark.circle.fill")
        }

        if let errorMessage = viewModel.errorMessage {
            messageBanner(errorMessage, systemImage: "wifi.exclamationmark")
        }
    }

    private var ownerCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Tokens.Space.md) {
                sectionTitle("Owner details", icon: "person.fill")

                fieldLabel("Full name")
                TextField("Mei Ling Chen", text: $viewModel.fullName)
                    .textInputAutocapitalization(.words)
                    .signupTextFieldStyle()

                fieldLabel("Email")
                TextField("you@example.com", text: $viewModel.email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .signupTextFieldStyle()

                fieldLabel("Phone")
                TextField("+60123456789", text: $viewModel.phone)
                    .keyboardType(.phonePad)
                    .signupTextFieldStyle()

                fieldLabel("Password")
                SecureField("At least 8 characters", text: $viewModel.password)
                    .textInputAutocapitalization(.never)
                    .signupTextFieldStyle()
            }
        }
    }

    private var petCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Tokens.Space.md) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.isPetSectionExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: Tokens.Space.sm) {
                        sectionTitle("First pet", icon: "pawprint.fill")

                        Spacer()

                        Image(systemName: viewModel.isPetSectionExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Tokens.Color.textSecondary)
                    }
                }
                .buttonStyle(.plain)

                if viewModel.isPetSectionExpanded {
                    fieldLabel("Pet type")
                    petTypeGrid

                    fieldLabel("Pet name")
                    TextField("Mochi", text: $viewModel.petName)
                        .textInputAutocapitalization(.words)
                        .signupTextFieldStyle()

                    fieldLabel("Weight")
                    TextField("4.2", text: $viewModel.petWeightKg)
                        .keyboardType(.decimalPad)
                        .signupTextFieldStyle(suffix: "kg")
                } else {
                    collapsedPetSummary
                }
            }
        }
    }

    private var petTypeGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Tokens.Space.sm) {
            ForEach(PetType.allCases, id: \.self) { petType in
                let isSelected = viewModel.selectedPetType == petType

                Button {
                    viewModel.selectedPetType = petType
                } label: {
                    HStack(spacing: Tokens.Space.xs) {
                        Image(systemName: icon(for: petType))
                            .font(.system(size: 15, weight: .semibold))
                        Text(viewModel.petTypeLabel(petType))
                            .font(Tokens.FontRole.label)
                    }
                    .foregroundStyle(isSelected ? Tokens.Color.onPrimaryTonal : Tokens.Color.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(isSelected ? Tokens.Color.primary : Tokens.Color.surfaceMuted)
                    .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var collapsedPetSummary: some View {
        HStack(alignment: .top, spacing: Tokens.Space.sm) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Tokens.Color.primary)

            VStack(alignment: .leading, spacing: 3) {
                Text("Add your pet info")
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.textPrimary)

                Text("Type, name, and weight are needed for transport planning.")
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Tokens.Space.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Tokens.Color.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
    }

    private var submitButton: some View {
        PrimaryButton(
            title: "Create account",
            icon: "arrow.right",
            isLoading: viewModel.isLoading
        ) {
            Task { await viewModel.submit() }
        }
    }

    private func sectionTitle(_ title: String, icon: String) -> some View {
        HStack(spacing: Tokens.Space.xs) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Tokens.Color.primary)

            Text(title)
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.textPrimary)
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

    private func icon(for petType: PetType) -> String {
        switch petType {
        case .cat:
            return "cat.fill"
        case .dog:
            return "dog.fill"
        case .bird:
            return "bird.fill"
        case .rabbit:
            return "hare.fill"
        case .reptile:
            return "lizard.fill"
        case .other:
            return "pawprint.fill"
        }
    }
}

private extension View {
    func signupTextFieldStyle(suffix: String? = nil) -> some View {
        HStack(spacing: Tokens.Space.sm) {
            self
                .font(Tokens.FontRole.body)
                .foregroundStyle(Tokens.Color.textPrimary)

            if let suffix {
                Text(suffix)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)
            }
        }
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
    SignupView(
        viewModel: SignupViewModel(
            email: "owner@kilat.my",
            password: "password123",
            fullName: "Mei Ling Chen",
            phone: "+60123456789",
            selectedPetType: .cat,
            petName: "Mochi",
            petWeightKg: "4.2",
            isPetSectionExpanded: true,
            authRepository: StubAuthRepository()
        )
    )
}
