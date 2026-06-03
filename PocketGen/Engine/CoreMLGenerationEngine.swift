import UIKit

/// The production engine slot: on-device diffusion gated on the model bundle being
/// downloaded and ready.
///
/// MOCK: until the Core ML pipeline (Apple's `ml-stable-diffusion` package) is wired in,
/// pixel production is delegated to `MockGenerationEngine` — but unlike the bare mock,
/// this engine enforces the production contract: it reports not-ready and refuses to run
/// until `ModelManager` says the model is installed, and it paces steps at the device
/// tier's realistic speed so progress and time estimates feel true.
final class CoreMLGenerationEngine: GenerationEngine {
    private let modelManager: ModelManager
    private let renderer: MockGenerationEngine
    private let tier = DeviceCapability.tier

    init(modelManager: ModelManager) {
        self.modelManager = modelManager
        self.renderer = MockGenerationEngine(secondsPerStep: DeviceCapability.tier.estimatedSecondsPerStep)
    }

    var isReady: Bool {
        // ModelManager is main-actor; this sync getter is only ever consulted from the
        // main-actor view model. `generate` must NOT use it — as a nonisolated async
        // method it runs on the global executor, where this assumption would trap.
        MainActor.assumeIsolated { modelManager.isReady }
    }

    func generate(
        _ request: GenerationRequest,
        progress: @escaping @MainActor (Double) -> Void
    ) async throws -> (image: UIImage, seed: UInt32) {
        guard await modelManager.isReady else { throw GenerationError.engineNotReady }
        // Larger canvases take proportionally longer, matching the up-front estimate.
        renderer.secondsPerStep = tier.estimatedSecondsPerStep * request.size.durationFactor
        return try await renderer.generate(request, progress: progress)
    }
}
