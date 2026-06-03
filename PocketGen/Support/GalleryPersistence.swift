import UIKit

/// Persists the gallery to disk so generation history survives relaunch.
/// Pixels live as one PNG per image under Application Support/Gallery; a JSON
/// manifest alongside carries the metadata (request, seed, creation date)
/// needed to rebuild each `GeneratedImage`. An actor so rapid add/remove
/// calls can't interleave manifest rewrites.
actor GalleryPersistence {

    /// On-disk metadata for one image. The pixels are in `<id>.png` next to the manifest.
    private struct Record: Codable {
        let id: UUID
        let request: GenerationRequest
        let seed: UInt32
        let createdAt: Date
    }

    private let directory: URL
    private var records: [Record] = []

    /// Default location: `Application Support/Gallery` (excluded from user-visible files,
    /// backed up with the app). Tests/previews can point elsewhere.
    init(directory: URL? = nil) {
        self.directory = directory ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Gallery", isDirectory: true)
    }

    /// Reads the manifest and image files, newest first, dropping any record
    /// whose PNG is missing or unreadable.
    func loadAll() -> [GeneratedImage] {
        guard let data = try? Data(contentsOf: manifestURL),
              let stored = try? decoder.decode([Record].self, from: data) else {
            return []
        }
        records = stored
        return stored.compactMap { record in
            guard let data = try? Data(contentsOf: imageURL(for: record.id)),
                  let image = UIImage(data: data) else { return nil }
            return GeneratedImage(
                id: record.id,
                image: image,
                request: record.request,
                seed: record.seed,
                createdAt: record.createdAt
            )
        }
    }

    /// Writes the PNG and prepends a record, mirroring `GalleryStore.add(_:)`'s
    /// newest-first ordering. Failures are silent: the image stays in the
    /// session gallery, it just won't survive relaunch.
    func save(_ image: GeneratedImage) {
        guard let data = image.image.pngData() else { return }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: imageURL(for: image.id), options: .atomic)
        } catch {
            return
        }
        records.insert(
            Record(id: image.id, request: image.request, seed: image.seed, createdAt: image.createdAt),
            at: 0
        )
        writeManifest()
    }

    func delete(_ id: UUID) {
        records.removeAll { $0.id == id }
        try? FileManager.default.removeItem(at: imageURL(for: id))
        writeManifest()
    }

    func deleteAll() {
        records.removeAll()
        try? FileManager.default.removeItem(at: directory)
    }

    // MARK: - Files

    private var manifestURL: URL { directory.appendingPathComponent("manifest.json") }

    private func imageURL(for id: UUID) -> URL {
        directory.appendingPathComponent("\(id.uuidString).png")
    }

    private func writeManifest() {
        guard let data = try? encoder.encode(records) else { return }
        try? data.write(to: manifestURL, options: .atomic)
    }

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
}
