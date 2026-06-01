import SwiftUI

/// App shell: a tab bar over the Create screen and the Gallery of generated images.
/// Owns the shared `GalleryStore` so generations on the Create tab show up under Gallery.
struct RootView: View {
    @StateObject private var gallery = GalleryStore()

    var body: some View {
        TabView {
            GenerateView(gallery: gallery)
                .tabItem {
                    Label("Create", systemImage: "sparkles")
                }

            GalleryView(gallery: gallery)
                .tabItem {
                    Label("Gallery", systemImage: "photo.on.rectangle.angled")
                }

            SettingsView(gallery: gallery)
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
