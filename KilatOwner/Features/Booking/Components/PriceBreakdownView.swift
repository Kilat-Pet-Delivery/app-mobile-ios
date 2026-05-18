import SwiftUI
import KilatUI

struct PriceBreakdownView: View {
    let booking: BookingDTO
    let payment: PaymentDTO?

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Tokens.Space.md) {
                HStack(spacing: Tokens.Space.sm) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Tokens.Color.primary)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Price")
                            .font(Tokens.FontRole.titleM)
                            .foregroundStyle(Tokens.Color.textPrimary)

                        Text(paymentStatus)
                            .font(Tokens.FontRole.caption)
                            .foregroundStyle(Tokens.Color.textSecondary)
                    }
                }

                VStack(spacing: Tokens.Space.sm) {
                    amountRow(title: "Transport estimate", cents: booking.estimatedPriceCents)

                    if let finalPriceCents = booking.finalPriceCents {
                        amountRow(title: "Final fare", cents: finalPriceCents)
                    }

                    if let platformFeeCents = payment?.platformFeeCents {
                        amountRow(title: "Platform fee", cents: platformFeeCents)
                    }

                    Divider()
                        .background(Tokens.Color.separator)

                    amountRow(title: "Total", cents: booking.amountCents, isTotal: true)
                }
            }
        }
    }

    private var paymentStatus: String {
        switch payment?.escrowStatus {
        case .pending:
            return "Payment pending"
        case .held:
            return "Escrow held"
        case .released:
            return "Escrow released"
        case .refunded:
            return "Refunded"
        case .failed:
            return "Payment failed"
        case nil:
            return "Payment not started"
        }
    }

    private func amountRow(title: String, cents: Int64, isTotal: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(isTotal ? Tokens.FontRole.label : Tokens.FontRole.body)
                .foregroundStyle(isTotal ? Tokens.Color.textPrimary : Tokens.Color.textSecondary)

            Spacer(minLength: Tokens.Space.md)

            Text(Self.format(cents: cents, currency: booking.currency))
                .font(isTotal ? Tokens.FontRole.titleM : Tokens.FontRole.body)
                .foregroundStyle(Tokens.Color.textPrimary)
                .monospacedDigit()
        }
    }

    private static func format(cents: Int64, currency: String) -> String {
        let prefix = currency == "MYR" ? "RM" : "\(currency) "
        return String(format: "\(prefix)%.2f", Double(cents) / 100.0)
    }
}
