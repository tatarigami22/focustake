import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var creditStore: CreditStore
    @EnvironmentObject private var sessionEngine: FocusSessionEngine
    @State private var showingSession = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(creditStore.balance)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                    Text("credits")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                Text("1 credit = 1 minute of unlocked apps. Earn credits by putting your phone down and staying focused.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                Button {
                    sessionEngine.start()
                    showingSession = true
                } label: {
                    Text("Start Focus Session")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .navigationTitle("Focustake")
            .fullScreenCover(isPresented: $showingSession) {
                FocusSessionView()
            }
        }
    }
}
