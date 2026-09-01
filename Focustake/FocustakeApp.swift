import SwiftUI

@main
struct FocustakeApp: App {
    @StateObject private var creditStore = CreditStore()
    @StateObject private var sessionEngine = FocusSessionEngine()
    @StateObject private var screenTimeManager = ScreenTimeManager()
    @StateObject private var unlockManager = UnlockManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(creditStore)
                .environmentObject(sessionEngine)
                .environmentObject(screenTimeManager)
                .environmentObject(unlockManager)
        }
    }
}
