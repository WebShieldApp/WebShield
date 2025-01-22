import ContentBlockerEngine
import Foundation
import OSLog

// MARK: - ContentBlockerEngineWrapper
actor ContentBlockerEngineWrapper {
    private let jsonURL: URL
    private let logger = Logger(subsystem: "dev.arjuna.WebShield", category: "Engine")
    private var engine: ContentBlockerEngine?
    private var lastModified: Date?
    static let shared = try? ContentBlockerEngineWrapper(appGroupID: "group.dev.arjuna.WebShield")

    init(appGroupID: String) throws {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
        else {
            throw EngineError.appGroupNotFound(appGroupID)
        }

        self.jsonURL = containerURL.appendingPathComponent("advancedBlocking.json")

        // Inline file existence check instead of calling actor-isolated method
        guard FileManager.default.fileExists(atPath: jsonURL.path) else {
            throw EngineError.fileNotFound(jsonURL)
        }
    }

    func getBlockingData(for url: URL) async throws -> String {
        //        try await reloadIfNeeded()
        try await loadEngine()
        return try engine?.getData(url: url) ?? ""
    }

    func makeChunkedReader() throws -> ChunkFileReader {
        try ChunkFileReader(fileURL: jsonURL)
    }

    private func reloadIfNeeded() async throws {
        let attrs = try FileManager.default.attributesOfItem(atPath: jsonURL.path)
        guard let modified = attrs[.modificationDate] as? Date else { return }

        if lastModified != modified || engine == nil {
            try await loadEngine()
            lastModified = modified
        }
    }

    private func loadEngine() async throws {
        let data = try Data(contentsOf: jsonURL)
        engine = try ContentBlockerEngine(String(decoding: data, as: UTF8.self))
    }

    private func validateFileExists() throws {
        guard FileManager.default.fileExists(atPath: jsonURL.path) else {
            throw EngineError.fileNotFound(jsonURL)
        }
    }

    enum EngineError: Error {
        case appGroupNotFound(String)
        case fileNotFound(URL)
        case engineInitialization(Error)
    }
}
