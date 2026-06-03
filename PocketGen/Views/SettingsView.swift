import SwiftUI

/// The Settings tab: hardware status, gallery + model storage, the unlock state,
/// the privacy pitch, and app info.
struct SettingsView: View {
    @ObservedObject var gallery: GalleryStore
    @ObservedObject var modelManager: ModelManager
    @ObservedObject var entitlements: EntitlementStore

    private let tier = DeviceCapability.tier

    @State private var showingClearConfirmation = false
    @State private var showingDeleteModelConfirmation = false
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Hardware") {
                    LabeledContent("Performance tier") {
                        Text(tier.name)
                            .foregroundStyle(tier == .recommended ? .green : .yellow)
                    }
                    if let banner = tier.banner {
                        Text(banner)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Storage") {
                    LabeledContent("Saved images", value: "\(gallery.images.count)")
                    Button("Clear Gallery", role: .destructive) {
                        showingClearConfirmation = true
                    }
                    .disabled(gallery.images.isEmpty)

                    LabeledContent("Image model") {
                        Text(modelStatusLabel)
                            .foregroundStyle(modelManager.isReady ? .green : .secondary)
                    }
                    if modelManager.isReady {
                        Button("Delete Model", role: .destructive) {
                            showingDeleteModelConfirmation = true
                        }
                    }
                }

                Section("Unlock") {
                    if entitlements.isUnlocked {
                        Label("Unlimited — unlocked forever", systemImage: "infinity.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        LabeledContent(
                            "Free creations left",
                            value: "\(entitlements.remainingFree) of \(EntitlementStore.freeAllowance)"
                        )
                        Button("Unlock unlimited (\(EntitlementStore.unlockPriceLabel), one-time)") {
                            showingPaywall = true
                        }
                        Button("Restore Purchases") {
                            Task { await entitlements.restorePurchases() }
                        }
                    }
                }

                Section("Privacy") {
                    Label(
                        "Generation runs entirely on your device. Your prompts and images never leave your iPhone.",
                        systemImage: "lock.shield"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                Section("About") {
                    LabeledContent("Version", value: Self.versionString)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .confirmationDialog(
                "Clear all generated images?",
                isPresented: $showingClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear Gallery", role: .destructive) { gallery.clear() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes every generated image from this device. It can't be undone.")
            }
            .confirmationDialog(
                "Delete the image model?",
                isPresented: $showingDeleteModelConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Model", role: .destructive) { modelManager.deleteModel() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This frees \(ModelManager.downloadSizeLabel) of storage. You'll need to download it again before creating images.")
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView(entitlements: entitlements)
            }
        }
    }

    private var modelStatusLabel: String {
        switch modelManager.state {
        case .ready: return "Downloaded (\(ModelManager.downloadSizeLabel))"
        case .downloading(let progress): return "Downloading… \(Int(progress * 100))%"
        case .verifying: return "Verifying…"
        case .notDownloaded, .failed: return "Not downloaded"
        }
    }

    /// Marketing version + build from the app bundle, e.g. "1.0 (1)".
    private static var versionString: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}

#Preview {
    SettingsView(gallery: GalleryStore(), modelManager: ModelManager(), entitlements: EntitlementStore())
        .preferredColorScheme(.dark)
}
