import Photos
import UIKit

/// Saves images to the user's photo library using add-only authorization,
/// the least-privilege scope for an app that only writes.
enum PhotoSaver {
    enum SaveError: LocalizedError {
        case denied
        case failed(String)

        var errorDescription: String? {
            switch self {
            case .denied:
                return "LocalGen needs permission to add photos. Enable it in Settings › LocalGen › Photos."
            case .failed(let message):
                return message
            }
        }
    }

    static func save(_ image: UIImage) async throws {
        let status = await requestAddAuthorization()
        guard status == .authorized || status == .limited else {
            throw SaveError.denied
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
        } catch {
            throw SaveError.failed(error.localizedDescription)
        }
    }

    private static func requestAddAuthorization() async -> PHAuthorizationStatus {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: status)
            }
        }
    }
}
