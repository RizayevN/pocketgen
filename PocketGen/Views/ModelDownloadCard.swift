import SwiftUI

/// Shown on the Create tab until the model bundle is installed: one card, one button,
/// no model-management jargon (PRD: invisible model management). Replaces the composer
/// entirely while the model isn't ready.
struct ModelDownloadCard: View {
    @ObservedObject var modelManager: ModelManager

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 44))
                .foregroundStyle(.purple)

            Text("One download, then it's all yours")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)

            Text("PocketGen creates images entirely on your iPhone. It needs a one-time download of \(ModelManager.downloadSizeLabel) — after that, everything works offline, forever.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            switch modelManager.state {
            case .notDownloaded, .failed:
                if case .failed(let message) = modelManager.state {
                    Label(message, systemImage: "xmark.octagon.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
                Button {
                    modelManager.download()
                } label: {
                    Label("Download (\(ModelManager.downloadSizeLabel))", systemImage: "arrow.down.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)

            case .downloading(let progress):
                VStack(spacing: 12) {
                    ProgressView(value: progress) {
                        Text("Downloading… \(Int(progress * 100))%")
                            .font(.footnote.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Button("Cancel", role: .cancel) {
                        modelManager.cancelDownload()
                    }
                    .buttonStyle(.bordered)
                }

            case .verifying:
                ProgressView {
                    Text("Checking download…")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

            case .ready:
                EmptyView()
            }
        }
        .padding(24)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ModelDownloadCard(modelManager: ModelManager())
            .padding(20)
    }
    .preferredColorScheme(.dark)
}
