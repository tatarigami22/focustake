import Foundation
import Combine

struct CreditTransaction: Identifiable, Codable {
    enum Kind: String, Codable {
        case earned
        case spent
        case refunded
        case bonus
    }

    let id: UUID
    let date: Date
    let kind: Kind
    let amount: Int
    let note: String

    init(id: UUID = UUID(), date: Date = Date(), kind: Kind, amount: Int, note: String) {
        self.id = id
        self.date = date
        self.kind = kind
        self.amount = amount
        self.note = note
    }
}

@MainActor
final class CreditStore: ObservableObject {
    @Published private(set) var balance: Int = 0
    @Published private(set) var transactions: [CreditTransaction] = []
    @Published private(set) var dailySpent: Int = 0
    @Published private(set) var dailySpentDate: Date = Date()

    let dailySpendCap = 120

    private let defaults = UserDefaults.standard
    private let balanceKey = "focustake.balance"
    private let transactionsKey = "focustake.transactions"
    private let dailySpentKey = "focustake.dailySpent"
    private let dailySpentDateKey = "focustake.dailySpentDate"

    init() {
        load()
        resetDailyCapIfNeeded()
    }

    var remainingDailySpendAllowance: Int {
        max(0, dailySpendCap - dailySpent)
    }

    func earn(minutes: Int, note: String = "Focus session") {
        guard minutes > 0 else { return }
        balance += minutes
        record(.earned, amount: minutes, note: note)
        save()
    }

    @discardableResult
    func spend(minutes: Int, note: String = "Unlocked app") -> Bool {
        resetDailyCapIfNeeded()
        guard minutes > 0, minutes <= balance, minutes <= remainingDailySpendAllowance else { return false }
        balance -= minutes
        dailySpent += minutes
        record(.spent, amount: minutes, note: note)
        save()
        return true
    }

    func refund(minutes: Int, note: String = "Early re-lock refund") {
        guard minutes > 0 else { return }
        balance += minutes
        dailySpent = max(0, dailySpent - minutes)
        record(.refunded, amount: minutes, note: note)
        save()
    }

    func claimBonus(minutes: Int, note: String) {
        guard minutes > 0 else { return }
        balance += minutes
        record(.bonus, amount: minutes, note: note)
        save()
    }

    private func record(_ kind: CreditTransaction.Kind, amount: Int, note: String) {
        transactions.insert(CreditTransaction(kind: kind, amount: amount, note: note), at: 0)
        if transactions.count > 200 {
            transactions.removeLast(transactions.count - 200)
        }
    }

    private func resetDailyCapIfNeeded() {
        if !Calendar.current.isDateInToday(dailySpentDate) {
            dailySpentDate = Date()
            dailySpent = 0
            save()
        }
    }

    private func save() {
        defaults.set(balance, forKey: balanceKey)
        defaults.set(dailySpent, forKey: dailySpentKey)
        defaults.set(dailySpentDate, forKey: dailySpentDateKey)
        if let encoded = try? JSONEncoder().encode(transactions) {
            defaults.set(encoded, forKey: transactionsKey)
        }
    }

    private func load() {
        balance = defaults.integer(forKey: balanceKey)
        dailySpent = defaults.integer(forKey: dailySpentKey)
        dailySpentDate = defaults.object(forKey: dailySpentDateKey) as? Date ?? Date()
        if let data = defaults.data(forKey: transactionsKey),
           let decoded = try? JSONDecoder().decode([CreditTransaction].self, from: data) {
            transactions = decoded
        }
    }
}
