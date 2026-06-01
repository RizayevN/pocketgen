import UIKit

/// A stand-in engine that produces a deterministic, prompt-derived abstract image while
/// simulating step-by-step diffusion progress. It lets the entire app (prompt → progress →
/// result → save/share) run and be tested today, with no model download.
///
/// Determinism: the same (prompt, negativePrompt, seed, size) always yields the same image,
/// mirroring how a real seeded diffusion run behaves — handy for "generate again".
final class MockGenerationEngine: GenerationEngine {
    var isReady: Bool { true }

    /// Tunable so previews/tests can run instantly; production-feel default otherwise.
    var secondsPerStep: Double

    init(secondsPerStep: Double = 0.08) {
        self.secondsPerStep = secondsPerStep
    }

    func generate(
        _ request: GenerationRequest,
        progress: @escaping @MainActor (Double) -> Void
    ) async throws -> (image: UIImage, seed: UInt32) {
        let seed = request.seed ?? UInt32.random(in: 0...UInt32.max)
        let steps = max(1, request.steps)

        await progress(0)
        for step in 1...steps {
            try await Task.sleep(nanoseconds: UInt64(secondsPerStep * 1_000_000_000))
            // Surfaces cancellation as GenerationError.cancelled to the caller.
            try Task.checkCancellation()
            let fraction = Double(step) / Double(steps)
            await progress(fraction)
        }

        let image = Self.render(request: request, seed: seed)
        return (image, seed)
    }

    // MARK: - Deterministic placeholder rendering

    /// Renders an abstract gradient-and-bloom composition seeded by the prompt, so different
    /// prompts visibly produce different images. Pure function of its inputs.
    private static func render(request: GenerationRequest, seed: UInt32) -> UIImage {
        let edge = CGFloat(request.size.pixels)
        let size = CGSize(width: edge, height: edge)

        // Combine the prompt hash with the seed into a small deterministic PRNG.
        var state = UInt64(seed) ^ (UInt64(bitPattern: Int64(request.prompt.hashValue)) &* 0x9E3779B97F4A7C15)
        func next() -> Double {
            state ^= state << 13
            state ^= state >> 7
            state ^= state << 17
            return Double(state % 10_000) / 10_000.0
        }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { ctx in
            let cg = ctx.cgContext

            // Base diagonal gradient between two prompt-derived hues.
            let hueA = next()
            let hueB = (hueA + 0.25 + next() * 0.5).truncatingRemainder(dividingBy: 1.0)
            let c1 = UIColor(hue: hueA, saturation: 0.65, brightness: 0.85, alpha: 1).cgColor
            let c2 = UIColor(hue: hueB, saturation: 0.7, brightness: 0.45, alpha: 1).cgColor
            let space = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: space, colors: [c1, c2] as CFArray, locations: [0, 1]) {
                cg.drawLinearGradient(
                    gradient,
                    start: .zero,
                    end: CGPoint(x: edge, y: edge),
                    options: []
                )
            }

            // Soft radial blooms whose count/position/size come from the PRNG.
            let blooms = 5 + Int(next() * 6)
            cg.setBlendMode(.plusLighter)
            for _ in 0..<blooms {
                let r = CGFloat(0.08 + next() * 0.28) * edge
                let cx = CGFloat(next()) * edge
                let cy = CGFloat(next()) * edge
                let hue = next()
                let color = UIColor(hue: hue, saturation: 0.8, brightness: 0.9, alpha: 0.55)
                if let radial = CGGradient(
                    colorsSpace: space,
                    colors: [color.cgColor, color.withAlphaComponent(0).cgColor] as CFArray,
                    locations: [0, 1]
                ) {
                    cg.drawRadialGradient(
                        radial,
                        startCenter: CGPoint(x: cx, y: cy), startRadius: 0,
                        endCenter: CGPoint(x: cx, y: cy), endRadius: r,
                        options: []
                    )
                }
            }

            // Watermark so the placeholder is never mistaken for a real generation.
            cg.setBlendMode(.normal)
            let label = "MOCK" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: edge * 0.05, weight: .heavy),
                .foregroundColor: UIColor.white.withAlphaComponent(0.35)
            ]
            let textSize = label.size(withAttributes: attrs)
            label.draw(
                at: CGPoint(x: edge - textSize.width - edge * 0.04,
                            y: edge - textSize.height - edge * 0.04),
                withAttributes: attrs
            )
        }
    }
}
