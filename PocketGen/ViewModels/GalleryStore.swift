import Foundation

/// Holds every image produced this session, newest first, so the Gallery tab
/// can show generation history. In-memory for the MVP (images are `UIImage`s);
/// the shape is ready for a persistence layer to drop in behind `add(_:)`.
@MainActor
final class GalleryStore: ObservableObject {
    @Published private(set) var images: [GeneratedImage] = []

    func add(_ image: GeneratedImage) {
        images.insert(image, at: 0)
    }

    func remove(_ image: GeneratedImage) {
        images.removeAll { $0.id == image.id }
    }
}
