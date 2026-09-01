# Focustake

Focustake is a Screen Time "credit economy" app for iOS. You earn credits by
staying focused with your phone face-down and untouched, then spend those
credits to unlock apps you've chosen to block — an independent take on the
screen-time-wallet idea, built from scratch in SwiftUI.

## How it works

- **Earn**: start a focus session on the Home tab. While the phone is set
  down and still (checked via CoreMotion's accelerometer), you earn 1 credit
  per minute. Pick the phone up and earning pauses until you set it back down.
- **Spend**: on the Unlock tab, grant Screen Time access, choose which apps
  or categories to gate, then spend credits to temporarily lift the shield
  for a chosen number of minutes (capped at a daily spending allowance).
  Re-locking early refunds the unused whole minutes back to your balance.
- **Track**: the History tab keeps a running ledger of every credit earned,
  spent, or refunded.

## Architecture

- `CreditStore` — the balance and transaction ledger, persisted to
  `UserDefaults` as JSON. Tracks a daily spend cap that resets at midnight.
- `FocusSessionEngine` — a monotonic-clock timer (`ProcessInfo.systemUptime`,
  not wall-clock time) gated by a `CMMotionManager` stillness check, so
  minutes only accrue while the phone is genuinely set down.
- `ScreenTimeManager` — wraps Apple's `FamilyControls` and `ManagedSettings`
  frameworks: requests Screen Time authorization, lets the user pick apps
  with `FamilyActivityPicker`, and applies/removes a `ManagedSettingsStore`
  shield. All calls are deferred until the user actively opts in (never at
  app launch), and every call is defensively wrapped — Screen Time
  authorization isn't fully exercisable in the iOS Simulator, so failures
  there are expected and handled gracefully with an inline message instead
  of crashing.
- `UnlockManager` — tracks the countdown on an active unlock window and
  computes the unused-minute refund if you re-lock early.
- SwiftUI views (`HomeView`, `FocusSessionView`, `UnlockView`, `HistoryView`)
  tied together by a `RootView` `TabView`.

## Requirements

- Xcode 26 or newer.
- Any Apple ID works for Simulator builds — a free "Personal Team" is fine,
  no paid Apple Developer Program membership required.
- `com.apple.developer.family-controls` is a restricted Apple entitlement.
  Xcode's automatic signing includes it for local development and Simulator
  testing, but real on-device app shielding in a shipped app requires Apple
  to grant the entitlement for your own bundle identifier and provisioning
  profile — see [Apple's Family Controls documentation](https://developer.apple.com/documentation/familycontrols)
  before distributing this beyond your own device.

## Setup

1. Clone this repo and open `Focustake.xcodeproj` in Xcode.
2. Select the `Focustake` target, go to **Signing & Capabilities**, and pick
   your own Apple ID under **Team** (Automatic signing is already on).
3. If you want your own bundle identifier / App Group instead of the
   defaults baked in here, change `PRODUCT_BUNDLE_IDENTIFIER` in the
   project's build settings.
4. Pick an iPhone Simulator as the run destination and hit Run. On a real
   device, note the entitlement caveat above — Screen Time authorization
   will only reach `.approved` once Apple has granted the entitlement for
   your bundle ID.
