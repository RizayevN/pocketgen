import Foundation

/// Holds every generated image, newest first, so the Gallery tab can show
/// generation history. Backed by `GalleryPersistence`: history is loaded from
/// disk on launch and every mutation is mirrored to disk, so the gallery
/// survives relaunch. The published array stays the synchronous source of
/// truth for the UI; disk work happens off the main actor.
@MainActor
final class GalleryStore: ObservableObject {
    @Published private(set) var images: [GeneratedImage] = []

    private let persistence: GalleryPersistence

    init(persistence: GalleryPersistence = GalleryPersistence()) {
        self.persistence = persistence
        Task {
            // Anything generated before the load finishes stays ahead of restored history.
            let restored = await persistence.loadAll()
            images.append(contentsOf: restored)
        }
    }

    func add(_ image: GeneratedImage) {
        images.insert(image, at: 0)
        Task { await persistence.save(image) }
    }

    func remove(_ image: GeneratedImage) {
        images.removeAll { $0.id == image.id }
        Task { await persistence.delete(image.id) }
    }

    func clear() {
        images.removeAll()
        Task { await persistence.deleteAll() }
    }
}
