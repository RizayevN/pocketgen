import SwiftUI
import UIKit

/// Save-to-Photos and system Share actions for a generated image.
/// Shared by the result screen and the gallery detail so the save/share
/// behaviour stays in one place.
struct ImageActions: View {
    let image: UIImage

    @State private var isSharing = false
    @State private var saveState: SaveState = .idle

    private enum SaveState: Equatable {
        case idle, saving, saved, failed(String)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: save) {
                    Label(saveLabel, systemImage: saveIcon)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .disabled(saveState == .saving || saveState == .saved)

                Button {
                    isSharing = true
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
            }

            if case .failed(let message) = saveState {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .sheet(isPresented: $isSharing) {
            ShareSheet(items: [image])
        }
    }

    private var saveLabel: String {
        switch saveState {
        case .idle, .failed: return "Save"
        case .saving: return "Saving…"
        case .saved: return "Saved"
        }
    }

    private var saveIcon: String {
        saveState == .saved ? "checkmark" : "square.and.arrow.down"
    }

    private func save() {
        saveState = .saving
        Task {
            do {
                try await PhotoSaver.save(image)
                saveState = .saved
            } catch {
                saveState = .failed(error.localizedDescription)
            }
        }
    }
}
