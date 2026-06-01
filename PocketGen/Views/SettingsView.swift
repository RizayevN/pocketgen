import SwiftUI

/// The Settings tab: hardware status, session storage, the privacy pitch, and app info.
/// Read-only for the MVP apart from clearing the in-memory gallery; the layout leaves
/// room for real preferences (default size/steps, model management) to drop in later.
struct SettingsView: View {
    @ObservedObject var gallery: GalleryStore

    private let tier = DeviceCapability.tier

    @State private var showingClearConfirmation = false

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
                    LabeledContent("Images this session", value: "\(gallery.images.count)")
                    Button("Clear Gallery", role: .destructive) {
                        showingClearConfirmation = true
                    }
                    .disabled(gallery.images.isEmpty)
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
                Text("This removes every image from this session. It can't be undone.")
            }
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
    SettingsView(gallery: GalleryStore())
        .preferredColorScheme(.dark)
}
