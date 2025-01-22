import Foundation

// MARK: - ChunkFileReader
actor ChunkFileReader: Sendable {
    private let fileHandle: FileHandle
    private let chunkSize: Int
    private let totalSize: UInt64

    init(fileURL: URL, chunkSize: Int = 32768) throws {
        self.fileHandle = try FileHandle(forReadingFrom: fileURL)
        self.chunkSize = chunkSize
        self.totalSize = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? UInt64 ?? 0
    }

    deinit {
        try? fileHandle.close()
    }

    func nextChunk() -> String? {
        do {
            guard let data = try fileHandle.read(upToCount: chunkSize), !data.isEmpty else { return nil }
            return String(decoding: data, as: UTF8.self)
        } catch {
            return nil
        }
    }

    func rewind() {
        try? fileHandle.seek(toOffset: 0)
    }

    var progress: Double {
        Double(fileHandle.offsetInFile) / Double(totalSize)
    }
}
