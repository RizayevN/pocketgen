import SwiftUI

/// Full-size view of a stored image with its provenance and save/share actions.
struct GalleryDetailView: View {
    let item: GeneratedImage

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(uiImage: item.image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 20)

                if !item.request.prompt.isEmpty {
                    Text(item.request.prompt)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text("Seed \(item.seed) · \(item.request.size.label)px · \(item.request.steps) steps")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ImageActions(image: item.image)
            }
            .padding(20)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Image")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
