import SwiftUI

/// The Gallery tab: a grid of every image generated this session, newest first.
struct GalleryView: View {
    @ObservedObject var gallery: GalleryStore

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 12)]

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
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(gallery.images) { item in
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
        }
    }
}
