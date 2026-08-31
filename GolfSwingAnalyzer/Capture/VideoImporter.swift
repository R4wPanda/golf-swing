import CoreTransferable
import PhotosUI
import UniformTypeIdentifiers

/// `PhotosPickerItem` doesn't expose a stable file URL directly — the
/// standard pattern is a small `Transferable` that copies the picked video
/// to a local temp file during import, since the system-provided URL is
/// only valid for the duration of the `importing` closure.
enum VideoImporter {
    enum ImportError: Error {
        case loadFailed
    }

    struct ImportedVideo: Transferable {
        let url: URL

        static var transferRepresentation: some TransferRepresentation {
            FileRepresentation(contentType: .movie) { video in
                SentTransferredFile(video.url)
            } importing: { received in
                let extensionName = received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension
                let destination = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(extensionName)
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.copyItem(at: received.file, to: destination)
                return Self(url: destination)
            }
        }
    }

    static func localURL(for item: PhotosPickerItem) async throws -> URL {
        guard let video = try await item.loadTransferable(type: ImportedVideo.self) else {
            throw ImportError.loadFailed
        }
        return video.url
    }
}
