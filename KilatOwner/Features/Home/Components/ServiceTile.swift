import SwiftUI
import KilatUI

struct ServiceTile: View {
    let service: Service
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Tokens.Space.sm) {
                ZStack {
                    Circle()
                        .fill(Tokens.Color.primaryTonal)

                    Image(systemName: service.iconSFSymbol)
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(Tokens.Color.onPrimaryTonal)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(service.name)
                        .font(Tokens.FontRole.label)
                        .foregroundStyle(Tokens.Color.textPrimary)
                        .lineLimit(1)

                    Text(service.leadTimeHint)
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(Tokens.Space.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 128)
            .background(Tokens.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous)
                    .stroke(Tokens.Color.separator, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
