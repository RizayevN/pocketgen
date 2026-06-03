import UIKit

/// Coarse hardware tier used to set expectations before the user generates.
///
/// PocketGen's pitch is unlimited *on-device* generation, which is only pleasant on an
/// A14-class chip or newer. We can't read the exact SoC from public API, so we map the
/// device model identifier (e.g. "iPhone13,2") to a tier. Unknown identifiers — including
/// the Simulator and future devices — are treated as `.recommended`, since erring toward
/// "you're fine" is better than scaring users on hardware we simply haven't catalogued.
enum DeviceTier {
    /// A14 / M1 or newer — the recommended experience.
    case recommended
    /// Runs, but generation will be slow. Worth a heads-up.
    case limited
    /// Below the supported floor (iPhone 11 / iPad 9th gen and older).
    case unsupported

    /// Short label for surfacing the tier in Settings.
    var name: String {
        switch self {
        case .recommended: return "Recommended"
        case .limited: return "Limited"
        case .unsupported: return "Below recommended"
        }
    }

    var banner: String? {
        switch self {
        case .recommended:
            return nil
        case .limited:
            return "This device can generate images, but slowly. An A14-class chip or newer is recommended."
        case .unsupported:
            return "This device is below PocketGen's recommended hardware. Generation may be very slow or unstable."
        }
    }

    /// Rough seconds per diffusion step at 512px, used for the up-front time estimate the
    /// user sees before committing to a generation (PRD: honest device expectations).
    /// Static table for now; once the real pipeline lands these get calibrated from
    /// measured on-device history.
    var estimatedSecondsPerStep: Double {
        switch self {
        case .recommended: return 0.5
        case .limited: return 1.2
        case .unsupported: return 2.5
        }
    }

    /// Human-readable estimate for a full request on this device, e.g. "about 10 seconds".
    func estimatedDuration(for request: GenerationRequest) -> String {
        let seconds = Double(request.steps) * estimatedSecondsPerStep * request.size.durationFactor
        if seconds < 90 {
            return "about \(Int(seconds.rounded())) seconds"
        }
        return "about \(Int((seconds / 60).rounded())) minutes"
    }
}

enum DeviceCapability {
    /// Numeric model identifier, e.g. "iPhone13,2" → (major: 13, minor: 2). Returns nil on Simulator.
    private static func modelNumbers() -> (prefix: String, major: Int, minor: Int)? {
        var systemInfo = utsname()
        uname(&systemInfo)
        let identifier = withUnsafeBytes(of: &systemInfo.machine) { raw -> String in
            let bytes = raw.bindMemory(to: CChar.self)
            return String(cString: bytes.baseAddress!)
        }
        // identifier looks like "iPhone13,2" or "iPad13,1"; Simulator gives "arm64"/"x86_64".
        guard let comma = identifier.firstIndex(of: ",") else { return nil }
        let head = identifier[..<comma]
        let prefix = head.prefix { !$0.isNumber }
        let majorStr = head.dropFirst(prefix.count)
        let minorStr = identifier[identifier.index(after: comma)...]
        guard let major = Int(majorStr), let minor = Int(minorStr) else { return nil }
        return (String(prefix), major, minor)
    }

    static var tier: DeviceTier {
        guard let m = modelNumbers() else { return .recommended } // Simulator / unknown → assume fine

        switch m.prefix {
        case "iPhone":
            // iPhone12,x = iPhone 11 family (A13). iPhone13,x = iPhone 12 family (A14) → recommended.
            if m.major >= 13 { return .recommended }
            if m.major == 12 { return .unsupported }
            return .unsupported
        case "iPad":
            // iPad models from 2020 onward broadly carry A12Z/A14/M-class silicon. Treat the
            // older numbered generations conservatively; newer identifiers are recommended.
            if m.major >= 13 { return .recommended }
            return .limited
        default:
            return .recommended
        }
    }
}
