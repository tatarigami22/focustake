import Foundation
import Combine

@MainActor
final class UnlockManager: ObservableObject {
    @Published private(set) var isUnlocked: Bool = false
    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var purchasedMinutes: Int = 0

    var onNaturalExpiration: (() -> Void)?

    private var timer: Timer?
    private var unlockStartUptime: TimeInterval = 0
    private var totalSeconds: Int = 0

    func startUnlock(minutes: Int) {
        purchasedMinutes = minutes
        totalSeconds = minutes * 60
        remainingSeconds = totalSeconds
        unlockStartUptime = ProcessInfo.processInfo.systemUptime
        isUnlocked = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func tick() {
        guard isUnlocked else { return }
        let elapsed = Int(ProcessInfo.processInfo.systemUptime - unlockStartUptime)
        remainingSeconds = max(0, totalSeconds - elapsed)
        if remainingSeconds == 0 {
            timer?.invalidate()
            timer = nil
            isUnlocked = false
            purchasedMinutes = 0
            onNaturalExpiration?()
        }
    }

    /// Ends the unlock early and returns the number of whole unused minutes to refund.
    @discardableResult
    func endUnlockEarly() -> Int {
        guard isUnlocked else { return 0 }
        timer?.invalidate()
        timer = nil
        let unusedMinutes = Int(ceil(Double(remainingSeconds) / 60.0))
        isUnlocked = false
        remainingSeconds = 0
        purchasedMinutes = 0
        totalSeconds = 0
        return unusedMinutes
    }
}
