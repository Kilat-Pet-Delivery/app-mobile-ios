import SwiftUI
import KilatUI

struct PetPickerRow: View {
    let pet: PetDTO
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Tokens.Space.sm) {
                Avatar(
                    name: pet.name,
                    size: 48,
                    bg: isSelected ? Tokens.Color.primary : Tokens.Color.primaryTonal,
                    fg: isSelected ? Tokens.Color.onPrimary : Tokens.Color.onPrimaryTonal
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(pet.name)
                        .font(Tokens.FontRole.label)
                        .foregroundStyle(Tokens.Color.textPrimary)

                    Text(pet.petType.rawValue.capitalized)
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: Tokens.Space.xs)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Tokens.Color.primary)
                }
            }
            .padding(Tokens.Space.md)
            .frame(width: 210, alignment: .leading)
            .background(Tokens.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous)
                    .stroke(isSelected ? Tokens.Color.primary : Tokens.Color.separator, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
