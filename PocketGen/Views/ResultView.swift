import SwiftUI

/// Shows the finished image and the two terminal actions for the MVP: save and share.
struct ResultView: View {
    let result: GeneratedImage
    let onNewImage: () -> Void

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

                ImageActions(image: result.image)

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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onNewImage) {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel("Close")
            }
        }
    }
}
