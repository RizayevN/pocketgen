import SwiftUI

@MainActor
final class GenerationViewModel: ObservableObject {
    /// Drives which UI is shown on the generate screen.
    enum Phase: Equatable {
        case idle
        case generating(progress: Double)
        case finished
        case failed(String)
    }

    @Published var request = GenerationRequest.default
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var result: GeneratedImage?

    let deviceTier = DeviceCapability.tier

    private let engine: GenerationEngine
    private var task: Task<Void, Never>?

    init(engine: GenerationEngine = MockGenerationEngine()) {
        self.engine = engine
    }

    var isGenerating: Bool {
        if case .generating = phase { return true }
        return false
    }

    var canGenerate: Bool {
        !request.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && engine.isReady
            && !isGenerating
    }

    func generate() {
        guard canGenerate else { return }
        let request = self.request
        result = nil
        phase = .generating(progress: 0)

        task = Task {
            do {
                let output = try await engine.generate(request) { [weak self] fraction in
                    self?.phase = .generating(progress: fraction)
                }
                self.result = GeneratedImage(
                    image: output.image,
                    request: request,
                    seed: output.seed,
                    createdAt: Date()
                )
                self.phase = .finished
            } catch is CancellationError {
                self.phase = .idle
            } catch let error as GenerationError {
                if case .cancelled = error {
                    self.phase = .idle
                } else {
                    self.phase = .failed(error.localizedDescription)
                }
            } catch {
                self.phase = .failed(error.localizedDescription)
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        phase = .idle
    }

    /// Return to the prompt screen, keeping the current settings for another run.
    func reset() {
        result = nil
        phase = .idle
    }
}
