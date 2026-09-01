import SwiftUI

struct FocusSessionView: View {
    @EnvironmentObject private var sessionEngine: FocusSessionEngine
    @EnvironmentObject private var creditStore: CreditStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text(timeString(sessionEngine.elapsedSeconds))
                .font(.system(size: 56, weight: .semibold, design: .rounded))
                .monospacedDigit()

            statusBadge

            VStack(spacing: 4) {
                Text("+\(sessionEngine.creditedMinutes)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
                Text("credits earned this session")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(role: .destructive) {
                sessionEngine.stop()
                dismiss()
            } label: {
                Text("End Session")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.bordered)
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .onAppear {
            sessionEngine.onMinuteEarned = { minutes in
                creditStore.earn(minutes: minutes)
            }
        }
    }

    private var statusBadge: some View {
        Group {
            switch sessionEngine.state {
            case .running:
                Label("Phone down — earning", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .paused(let reason):
                Label(reason, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            case .idle:
                Label("Ready", systemImage: "circle")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.subheadline)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
