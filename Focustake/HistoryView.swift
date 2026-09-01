import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var creditStore: CreditStore

    var body: some View {
        NavigationStack {
            List {
                if creditStore.transactions.isEmpty {
                    Text("No activity yet. Start a focus session to earn your first credits.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(creditStore.transactions) { transaction in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(transaction.note)
                                    .font(.body)
                                Text(transaction.date, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(amountText(transaction))
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(color(transaction))
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }

    private func amountText(_ transaction: CreditTransaction) -> String {
        switch transaction.kind {
        case .earned, .refunded, .bonus:
            return "+\(transaction.amount)"
        case .spent:
            return "-\(transaction.amount)"
        }
    }

    private func color(_ transaction: CreditTransaction) -> Color {
        switch transaction.kind {
        case .earned, .refunded, .bonus:
            return .green
        case .spent:
            return .red
        }
    }
}
