import SwiftUI

/// The one and only purchase screen: a single one-time unlock, framed as the
/// anti-subscription (PRD: honest one-time unlock). Free and paid users get
/// identical features and quality — the unlock only removes the allowance cap.
struct PaywallView: View {
    @ObservedObject var entitlements: EntitlementStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "infinity.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.purple)

            Text("Everything, forever.")
                .font(.largeTitle.weight(.bold))

            Text("You've used your \(EntitlementStore.freeAllowance) free creations. One purchase unlocks unlimited generation — for good.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                bullet("Unlimited image generation, forever")
                bullet("No subscription. No credits. No meter.")
                bullet("Every feature is already included")
                bullet("Still 100% on your device — nothing is uploaded")
            }
            .padding(20)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))

            Spacer()

            Button {
                Task {
                    await entitlements.purchase()
                    dismiss()
                }
            } label: {
                Group {
                    if entitlements.isPurchasing {
                        ProgressView()
                    } else {
                        Text("Unlock for \(EntitlementStore.unlockPriceLabel) — once")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(entitlements.isPurchasing)

            Button("Restore Purchases") {
                Task {
                    await entitlements.restorePurchases()
                    dismiss()
                }
            }
            .font(.footnote)
            .disabled(entitlements.isPurchasing)

            Button("Not now") { dismiss() }
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private func bullet(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(.subheadline)
            .foregroundStyle(.primary)
    }
}

#Preview {
    PaywallView(entitlements: EntitlementStore())
}
