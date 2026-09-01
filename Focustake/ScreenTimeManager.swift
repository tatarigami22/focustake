import Foundation
import Combine
#if canImport(FamilyControls)
import FamilyControls
#endif
#if canImport(ManagedSettings)
import ManagedSettings
#endif

@MainActor
final class ScreenTimeManager: ObservableObject {
#if canImport(FamilyControls)
    @Published private(set) var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var selection = FamilyActivitySelection()
    private let center = AuthorizationCenter.shared
#endif
    @Published private(set) var isShielded: Bool = false
    @Published private(set) var authorizationErrorMessage: String?

#if canImport(ManagedSettings)
    private let store = ManagedSettingsStore()
#endif

    init() {
        // Deliberately not reading AuthorizationCenter.shared.authorizationStatus here.
        // Touching the Family Controls daemon eagerly at app launch can hang the main
        // thread when that daemon isn't reachable (e.g. in the iOS Simulator). Status is
        // only checked lazily, when the user actively taps "Enable Screen Time Access".
    }

    var isAuthorized: Bool {
#if canImport(FamilyControls)
        return authorizationStatus == .approved
#else
        return false
#endif
    }

    func requestAuthorization() async {
#if canImport(FamilyControls)
        do {
            try await center.requestAuthorization(for: .individual)
            authorizationStatus = center.authorizationStatus
            authorizationErrorMessage = nil
        } catch {
            authorizationErrorMessage = "Screen Time authorization isn't available here (\(error.localizedDescription)). This is expected on Simulator."
        }
#else
        authorizationErrorMessage = "Screen Time is not available on this platform."
#endif
    }

    func applyShield() {
#if canImport(FamilyControls) && canImport(ManagedSettings)
        guard isAuthorized else { return }
        let hasApps = !selection.applicationTokens.isEmpty
        let hasCategories = !selection.categoryTokens.isEmpty
        store.shield.applications = hasApps ? selection.applicationTokens : nil
        store.shield.applicationCategories = hasCategories ? .specific(selection.categoryTokens) : nil
        isShielded = hasApps || hasCategories
#endif
    }

    func removeShield() {
#if canImport(ManagedSettings)
        store.shield.applications = nil
        store.shield.applicationCategories = nil
#endif
        isShielded = false
    }
}
