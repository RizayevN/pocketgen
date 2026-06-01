import UIKit

/// The result of a successful generation, paired with the request that produced it
/// so the UI can show provenance and offer "generate again with same settings".
struct GeneratedImage: Identifiable {
    let id = UUID()
    let image: UIImage
    let request: GenerationRequest
    let seed: UInt32
    let createdAt: Date
}
