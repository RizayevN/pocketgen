import SwiftUI

/// The Gallery tab: a grid of every generated image, newest first,
/// searchable by the prompt that produced each image.
struct GalleryView: View {
    @ObservedObject var gallery: GalleryStore
    @State private var searchText = ""

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 12)]

    private var filteredImages: [GeneratedImage] {
        guard !searchText.isEmpty else { return gallery.images }
        return gallery.images.filter {
            $0.request.prompt.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if gallery.images.isEmpty {
                    ContentUnavailableView(
                        "No images yet",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text("Images you generate on the Create tab will appear here.")
                    )
                } else if filteredImages.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(filteredImages) { item in
                                NavigationLink {
                                    GalleryDetailView(item: item)
                                } label: {
                                    Image(uiImage: item.image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 110)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search prompts")
        }
    }
}
