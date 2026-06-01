import UIKit

/// Errors an engine can surface to the UI.
enum GenerationError: LocalizedError {
    case cancelled
    case engineNotReady
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .cancelled: return "Generation was cancelled."
        case .engineNotReady: return "The generation engine isn't ready yet."
        case .failed(let message): return message
        }
    }
}

/// The seam between the UI and whatever actually produces pixels.
///
/// Today this is backed by `MockGenerationEngine`. A real on-device pipeline
/// (Apple's `ml-stable-diffusion` Core ML package) only needs to conform to this
/// same protocol — no UI or view-model changes required.
protocol GenerationEngine: AnyObject {
    /// Whether the engine can accept work right now (models loaded, etc.).
    var isReady: Bool { get }

    /// Produce an image for `request`.
    /// - Parameter progress: called on the main actor with values in 0...1.
    /// - Returns: the finished image and the seed actually used.
    /// - Throws: `GenerationError`, including `.cancelled` if the task is cancelled.
    func generate(
        _ request: GenerationRequest,
        progress: @escaping @MainActor (Double) -> Void
    ) async throws -> (image: UIImage, seed: UInt32)
}
