import SwiftUI

/// Shows the finished image and the two terminal actions for the MVP: save and share.
struct ResultView: View {
    let result: GeneratedImage
    let onNewImage: () -> Void

    @State private var isSharing = false
    @State private var saveState: SaveState = .idle

    private enum SaveState: Equatable {
        case idle, saving, saved, failed(String)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(uiImage: result.image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 20)

                if !result.request.prompt.isEmpty {
                    Text(result.request.prompt)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text("Seed \(result.seed) · \(result.request.size.label)px · \(result.request.steps) steps")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)

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

                Button(action: onNewImage) {
                    Label("New image", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
            }
            .padding(20)
        }
        .sheet(isPresented: $isSharing) {
            ShareSheet(items: [result.image])
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
                try await PhotoSaver.save(result.image)
                saveState = .saved
            } catch {
                saveState = .failed(error.localizedDescription)
            }
        }
    }
}
