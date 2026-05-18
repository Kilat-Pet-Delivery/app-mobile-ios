import SwiftUI
import KilatUI

struct PetCardView: View {
    let petSpec: PetSpecDTO

    var body: some View {
        Card {
            HStack(alignment: .top, spacing: Tokens.Space.md) {
                Avatar(name: petSpec.name, size: 56)

                VStack(alignment: .leading, spacing: Tokens.Space.sm) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(petSpec.name)
                            .font(Tokens.FontRole.titleM)
                            .foregroundStyle(Tokens.Color.textPrimary)

                        Text(summary)
                            .font(Tokens.FontRole.body)
                            .foregroundStyle(Tokens.Color.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if !petSpec.specialNeeds.isEmpty {
                        HStack(alignment: .top, spacing: Tokens.Space.xs) {
                            Image(systemName: "heart.text.square.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Tokens.Color.primary)

                            Text(petSpec.specialNeeds)
                                .font(Tokens.FontRole.caption)
                                .foregroundStyle(Tokens.Color.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, Tokens.Space.sm)
                        .padding(.vertical, Tokens.Space.xs)
                        .background(Tokens.Color.primaryTonal.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous))
                    }
                }

                Spacer(minLength: Tokens.Space.xs)
            }
        }
    }

    private var summary: String {
        let breed = petSpec.breed.isEmpty ? petSpec.petType.rawValue.capitalized : petSpec.breed
        return "\(breed) • \(String(format: "%.1f", petSpec.weightKg)) kg"
    }
}
