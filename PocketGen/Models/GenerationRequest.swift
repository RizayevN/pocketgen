import Foundation

/// Output dimensions offered to the user. Values are square edge lengths in pixels,
/// chosen to match common on-device Stable Diffusion configurations.
enum ImageSize: Int, CaseIterable, Identifiable {
    case small = 384
    case standard = 512
    case large = 768

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .small: return "384"
        case .standard: return "512"
        case .large: return "768"
        }
    }

    var pixels: Int { rawValue }
}

/// A fully specified image-generation job. This is the unit the engine consumes,
/// so the same value can later be persisted, replayed, or fed to a real Core ML pipeline.
struct GenerationRequest: Equatable {
    var prompt: String
    var negativePrompt: String
    var size: ImageSize
    var steps: Int
    /// `nil` means a fresh random seed is chosen at generation time.
    var seed: UInt32?

    static let `default` = GenerationRequest(
        prompt: "",
        negativePrompt: "",
        size: .standard,
        steps: 20,
        seed: nil
    )

    /// Steps the UI lets the user pick between. More steps ≈ more detail, slower generation.
    static let stepRange: ClosedRange<Double> = 10...40
}
