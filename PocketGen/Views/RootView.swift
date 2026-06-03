import SwiftUI

/// App shell: a tab bar over the Create screen and the Gallery of generated images.
/// Owns the shared stores — `GalleryStore` so generations on the Create tab show up
/// under Gallery, `ModelManager` so the download state survives tab switches, and
/// `EntitlementStore` so the allowance/unlock is consistent across Create and Settings.
struct RootView: View {
    @StateObject private var gallery = GalleryStore()
    @StateObject private var modelManager = ModelManager()
    @StateObject private var entitlements = EntitlementStore()

    var body: some View {
        TabView {
            GenerateView(gallery: gallery, modelManager: modelManager, entitlements: entitlements)
                .tabItem {
                    Label("Create", systemImage: "sparkles")
                }

            GalleryView(gallery: gallery)
                .tabItem {
                    Label("Gallery", systemImage: "photo.on.rectangle.angled")
                }

            SettingsView(gallery: gallery, modelManager: modelManager, entitlements: entitlements)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    RootView()
        .preferredColorScheme(.dark)
}
