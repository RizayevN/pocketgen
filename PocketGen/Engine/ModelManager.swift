import Foundation

/// Manages the single curated on-device model bundle: not downloaded → downloading →
/// verifying → ready. The Create tab gates generation on `isReady`; Settings exposes
/// the installed size and a delete affordance.
///
/// MOCK: the "download" is simulated (no network, no bytes on disk) — only an installed
/// flag is persisted. The real implementation will stream a ~1.6 GB Core ML bundle from
/// a CDN via a resumable background `URLSession` and checksum-verify it before flipping
/// to `.ready`. The state machine, persistence point, and UI contract are final; only
/// the transport is fake.
@MainActor
final class ModelManager: ObservableObject {
    enum State: Equatable {
        case notDownloaded
        case downloading(progress: Double)
        case verifying
        case ready
        case failed(String)
    }

    /// Advertised size of the curated model bundle, shown before download and in Settings.
    static let downloadSizeLabel = "1.6 GB"

    @Published private(set) var state: State

    private var downloadTask: Task<Void, Never>?
    private let defaults: UserDefaults
    private static let installedKey = "model.installed"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        state = defaults.bool(forKey: Self.installedKey) ? .ready : .notDownloaded
    }

    var isReady: Bool { state == .ready }

    var isDownloading: Bool {
        if case .downloading = state { return true }
        return false
    }

    /// Starts (or restarts after a failure) the one-time model download.
    func download() {
        switch state {
        case .notDownloaded, .failed: break
        default: return
        }
        state = .downloading(progress: 0)
        downloadTask = Task {
            // Simulated resumable download: 1% ticks over a few seconds.
            for tick in 1...100 {
                do { try await Task.sleep(nanoseconds: 40_000_000) } catch { return }
                state = .downloading(progress: Double(tick) / 100)
            }
            state = .verifying
            try? await Task.sleep(nanoseconds: 500_000_000)
            defaults.set(true, forKey: Self.installedKey)
            state = .ready
        }
    }

    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        state = .notDownloaded
    }

    /// Frees the model storage (Settings). The user can re-download any time.
    func deleteModel() {
        defaults.set(false, forKey: Self.installedKey)
        state = .notDownloaded
    }
}
