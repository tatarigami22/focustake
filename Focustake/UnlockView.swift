import SwiftUI
#if canImport(FamilyControls)
import FamilyControls
#endif

struct UnlockView: View {
    @EnvironmentObject private var creditStore: CreditStore
    @EnvironmentObject private var screenTimeManager: ScreenTimeManager
    @EnvironmentObject private var unlockManager: UnlockManager

    @State private var minutesToSpend: Int = 15
    @State private var showingPicker = false

    var body: some View {
        NavigationStack {
            List {
                Section("Blocked Apps") {
                    if screenTimeManager.isAuthorized {
                        Button {
                            showingPicker = true
                        } label: {
                            Label("Choose Apps to Gate", systemImage: "square.grid.2x2")
                        }
                    } else {
                        Button {
                            Task { await screenTimeManager.requestAuthorization() }
                        } label: {
                            Label("Enable Screen Time Access", systemImage: "lock.shield")
                        }
                        if let message = screenTimeManager.authorizationErrorMessage {
                            Text(message)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if unlockManager.isUnlocked {
                    Section("Unlocked") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(unlockManager.remainingSeconds / 60):\(String(format: "%02d", unlockManager.remainingSeconds % 60)) remaining")
                                .font(.title2.monospacedDigit())
                            Button(role: .destructive) {
                                relockEarly()
                            } label: {
                                Text("Re-lock Now & Refund Unused Time")
                            }
                        }
                    }
                } else {
                    Section("Spend Credits to Unlock") {
                        Stepper(value: $minutesToSpend, in: 1...max(1, creditStore.remainingDailySpendAllowance), step: 5) {
                            Text("\(minutesToSpend) minutes")
                        }
                        Text("Balance: \(creditStore.balance) - Today's remaining allowance: \(creditStore.remainingDailySpendAllowance)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button {
                            unlock()
                        } label: {
                            Text("Unlock for \(minutesToSpend) min")
                        }
                        .disabled(minutesToSpend > creditStore.balance || minutesToSpend > creditStore.remainingDailySpendAllowance)
                    }
                }
            }
            .navigationTitle("Unlock Apps")
        }
#if canImport(FamilyControls)
        .familyActivityPicker(isPresented: $showingPicker, selection: $screenTimeManager.selection)
        .onChange(of: screenTimeManager.selection) { _, _ in
            if !unlockManager.isUnlocked {
                screenTimeManager.applyShield()
            }
        }
#endif
        .onAppear {
            unlockManager.onNaturalExpiration = {
                screenTimeManager.applyShield()
            }
        }
    }

    private func unlock() {
        guard creditStore.spend(minutes: minutesToSpend, note: "Unlocked apps for \(minutesToSpend) min") else { return }
        screenTimeManager.removeShield()
        unlockManager.startUnlock(minutes: minutesToSpend)
    }

    private func relockEarly() {
        let unused = unlockManager.endUnlockEarly()
        screenTimeManager.applyShield()
        if unused > 0 {
            creditStore.refund(minutes: unused, note: "Early re-lock refund")
        }
    }
}
