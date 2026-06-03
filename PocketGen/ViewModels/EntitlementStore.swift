import Foundation

/// Free-allowance plus one-time unlock. PocketGen never meters paid users and never
/// gates features: the first `freeAllowance` generations are free, then a single
/// one-time purchase unlocks unlimited generation forever. Nothing else is ever paid.
///
/// MOCK: purchase and restore are simulated with a short delay. The real implementation
/// swaps these for StoreKit 2, with `Transaction.currentEntitlements` as the single
/// source of truth re-checked at launch.
@MainActor
final class EntitlementStore: ObservableObject {
    /// Lifetime free generations before the unlock is offered. Tunable in beta (PRD §10).
    static let freeAllowance = 10
    /// Launch-price assumption; the real value comes from the StoreKit product.
    static let unlockPriceLabel = "$9.99"

    @Published private(set) var generationsUsed: Int
    @Published private(set) var isUnlocked: Bool
    @Published private(set) var isPurchasing = false

    private let defaults: UserDefaults
    private static let usedKey = "entitlement.generationsUsed"
    private static let unlockedKey = "entitlement.unlocked"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        generationsUsed = defaults.integer(forKey: Self.usedKey)
        isUnlocked = defaults.bool(forKey: Self.unlockedKey)
    }

    var remainingFree: Int { max(0, Self.freeAllowance - generationsUsed) }

    /// Whether another generation is allowed right now (unlocked, or allowance left).
    var canGenerate: Bool { isUnlocked || remainingFree > 0 }

    /// Called once per successful generation; unlocked users are never counted.
    func recordGeneration() {
        guard !isUnlocked else { return }
        generationsUsed += 1
        defaults.set(generationsUsed, forKey: Self.usedKey)
    }

    /// MOCK purchase: simulates the StoreKit round-trip, then unlocks.
    func purchase() async {
        guard !isUnlocked, !isPurchasing else { return }
        isPurchasing = true
        try? await Task.sleep(nanoseconds: 800_000_000)
        unlock()
        isPurchasing = false
    }

    /// MOCK restore: with no transaction history to query, behaves like a purchase.
    func restorePurchases() async {
        await purchase()
    }

    private func unlock() {
        isUnlocked = true
        defaults.set(true, forKey: Self.unlockedKey)
    }
}
