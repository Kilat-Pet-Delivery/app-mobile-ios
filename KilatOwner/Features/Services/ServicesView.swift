import SwiftUI
import KilatUI

struct ServicesView: View {
    @Bindable var viewModel: ServicesViewModel

    private let columns = [
        GridItem(.flexible(), spacing: Tokens.Space.sm),
        GridItem(.flexible(), spacing: Tokens.Space.sm)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.xl) {
                header
                banners
                petPickerSection
                serviceGrid
            }
            .padding(.horizontal, Tokens.Space.lg)
            .padding(.vertical, Tokens.Space.xxl)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            Text("Kilat Owner")
                .font(Tokens.FontRole.caption)
                .foregroundStyle(Tokens.Color.primary)

            Text("Services")
                .font(Tokens.FontRole.displayL)
                .foregroundStyle(Tokens.Color.textPrimary)

            Text("Pick a pet, then choose the run they need.")
                .font(Tokens.FontRole.body)
                .foregroundStyle(Tokens.Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var banners: some View {
        if let promptMessage = viewModel.promptMessage {
            messageBanner(promptMessage, systemImage: "exclamationmark.circle.fill", isError: false)
        }

        if let errorMessage = viewModel.errorMessage {
            messageBanner(errorMessage, systemImage: "wifi.exclamationmark", isError: true)
        }
    }

    @ViewBuilder
    private var petPickerSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.md) {
            sectionHeader(title: "Who's riding?", icon: "pawprint.fill")

            if viewModel.showsAddPetCTA {
                noPetsCard
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Tokens.Space.sm) {
                        ForEach(viewModel.pets) { pet in
                            PetPickerRow(
                                pet: pet,
                                isSelected: viewModel.selectedPetID == pet.id.uuidString
                            ) {
                                viewModel.selectPet(pet)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var noPetsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Tokens.Space.md) {
                HStack(alignment: .top, spacing: Tokens.Space.md) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Tokens.Color.primary)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                        Text("Add a pet first")
                            .font(Tokens.FontRole.label)
                            .foregroundStyle(Tokens.Color.textPrimary)

                        Text("Pet details are needed before transport can be planned.")
                            .font(Tokens.FontRole.caption)
                            .foregroundStyle(Tokens.Color.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                SecondaryButton(title: "Add a pet", icon: "plus") {
                    viewModel.addPetTapped()
                }
            }
        }
    }

    private var serviceGrid: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.md) {
            sectionHeader(title: "Choose service", icon: "square.grid.2x2.fill")

            LazyVGrid(columns: columns, spacing: Tokens.Space.sm) {
                ForEach(viewModel.services) { service in
                    serviceTile(service)
                }
            }
        }
    }

    private func serviceTile(_ service: Service) -> some View {
        Button {
            viewModel.serviceTileTapped(service)
        } label: {
            VStack(alignment: .leading, spacing: Tokens.Space.sm) {
                HStack(alignment: .top) {
                    ZStack {
                        Circle()
                            .fill(Tokens.Color.primaryTonal)

                        Image(systemName: service.iconSFSymbol)
                            .font(.system(size: 21, weight: .bold))
                            .foregroundStyle(Tokens.Color.onPrimaryTonal)
                    }
                    .frame(width: 44, height: 44)

                    Spacer(minLength: Tokens.Space.sm)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Tokens.Color.textSecondary)
                        .padding(.top, 3)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(service.name)
                        .font(Tokens.FontRole.label)
                        .foregroundStyle(Tokens.Color.textPrimary)
                        .lineLimit(1)

                    Text(service.description)
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.textSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Text(service.leadTimeHint)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.primary)
                    .lineLimit(1)
            }
            .padding(Tokens.Space.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 184)
            .background(Tokens.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous)
                    .stroke(Tokens.Color.separator, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: Tokens.Space.xs) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Tokens.Color.primary)

            Text(title)
                .font(Tokens.FontRole.titleM)
                .foregroundStyle(Tokens.Color.textPrimary)
        }
    }

    private func messageBanner(_ text: String, systemImage: String, isError: Bool) -> some View {
        HStack(alignment: .top, spacing: Tokens.Space.xs) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .padding(.top, 1)

            Text(text)
                .font(Tokens.FontRole.caption)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(isError ? Tokens.Color.destructive : Tokens.Color.primary)
        .padding(Tokens.Space.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous)
                .fill((isError ? Tokens.Color.destructive : Tokens.Color.primary).opacity(0.10))
        )
    }
}

#Preview {
    ServicesView(
        viewModel: ServicesViewModel(
            petRepository: StubPetRepository(),
            prefilledPetID: SampleData.mochiID.uuidString,
            initialPets: [SampleData.mochiPet, SampleData.baoPet]
        )
    )
}
