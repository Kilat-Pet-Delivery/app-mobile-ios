import SwiftUI
import KilatUI

struct PetRow: View {
    let pet: PetDTO

    var body: some View {
        HStack(spacing: Tokens.Space.sm) {
            Avatar(name: pet.name, size: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(pet.name)
                    .font(Tokens.FontRole.label)
                    .foregroundStyle(Tokens.Color.textPrimary)

                Text(pet.petType.rawValue.capitalized)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .lineLimit(1)

                Text("\(String(format: "%.1f", pet.weightKg)) kg")
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: Tokens.Space.sm)
        }
        .padding(Tokens.Space.md)
        .frame(width: 170, alignment: .leading)
        .background(Tokens.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous)
                .stroke(Tokens.Color.separator, lineWidth: 1)
        )
    }

}
