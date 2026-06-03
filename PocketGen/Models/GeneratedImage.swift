import UIKit

/// The result of a successful generation, paired with the request that produced it
/// so the UI can show provenance and offer "generate again with same settings".
struct GeneratedImage: Identifiable, Sendable {
    let id: UUID
    let image: UIImage
    let request: GenerationRequest
    let seed: UInt32
    let createdAt: Date

    init(id: UUID = UUID(), image: UIImage, request: GenerationRequest, seed: UInt32, createdAt: Date) {
        self.id = id
        self.image = image
        self.request = request
        self.seed = seed
        self.createdAt = createdAt
    }
}
