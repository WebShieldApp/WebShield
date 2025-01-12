@preconcurrency import ContentBlockerEngine
import Foundation
import OSLog

final class ContentBlockerEngineWrapper: Sendable {
    // MARK: - Types

    struct AppGroupID: Sendable {
        let value: String
    }

    enum ContentBlockerError: Error {
        case invalidAppGroupID(String)
        case fileNotFound(URL)
        case fileReadError(URL, Error)
        case jsonDecodeError(URL, Error)
        case engineInitializationError(Error)
        case dataRetrievalError(URL, Error)
        case invalidJSONData(URL)  // New error case for invalid JSON
    }

    // MARK: - Properties

    private let contentBlockerEngine: ContentBlockerEngine
    private let logger: Logger

    static let shared = ContentBlockerEngineWrapper()

    // MARK: - Initializers

    private init() {
        self.logger = Logger(subsystem: "dev.arjuna.WebShield.Advanced", category: "ContentBlockerEngineWrapper")

        let appGroupID = AppGroupID(value: "group.dev.arjuna.WebShield")

        do {
            self.contentBlockerEngine = try ContentBlockerEngineWrapper.initializeEngine(
                for: appGroupID, logger: logger)
        } catch {
            logger.error("Fatal error: \(error.localizedDescription, privacy: .public)")
            fatalError("Failed to initialize ContentBlockerEngineWrapper: \(error)")
        }
    }

    // MARK: - Initialization Logic

    private static func initializeEngine(for appGroupID: AppGroupID, logger: Logger) throws -> ContentBlockerEngine {
        let advancedBlockingURL = try getAdvancedBlockingURL(for: appGroupID)
        logger.log("advancedBlocking.json URL: \(advancedBlockingURL.absoluteString, privacy: .public)")

        let jsonData = try loadJSONData(from: advancedBlockingURL, logger: logger)

        // Decode JSON on a background thread
        return try createContentBlockerEngine(with: jsonData, url: advancedBlockingURL, logger: logger)
    }

    // MARK: - URL Construction

    private static func getAdvancedBlockingURL(for appGroupID: AppGroupID) throws -> URL {
        guard
            let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID.value)
        else {
            throw ContentBlockerError.invalidAppGroupID(appGroupID.value)
        }

        let fileURL = containerURL.appendingPathComponent("advancedBlocking.json", isDirectory: false)
        return fileURL
    }

    // MARK: - JSON Loading and Decoding

    private static func loadJSONData(from url: URL, logger: Logger) throws -> Data {
        logger.log("Attempting to read advancedBlocking.json")

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ContentBlockerError.fileNotFound(url)
        }

        do {
            return try Data(contentsOf: url)
        } catch {
            throw ContentBlockerError.fileReadError(url, error)
        }
    }

    private static func createContentBlockerEngine(with data: Data, url: URL, logger: Logger) throws
        -> ContentBlockerEngine
    {
        do {
            // First, attempt to decode the Data into a String
            guard let jsonString = String(data: data, encoding: .utf8) else {
                throw ContentBlockerError.invalidJSONData(url)
            }

            logger.log("Attempting to create ContentBlockerEngine")
            // Now pass the jsonString to the ContentBlockerEngine initializer
            let engine = try ContentBlockerEngine(jsonString)
            logger.log("ContentBlockerEngine initialized successfully")
            return engine
        } catch {
            logger.error("Failed to initialize content blocker: \(error.localizedDescription, privacy: .public)")
            throw ContentBlockerError.engineInitializationError(error)
        }
    }

    // MARK: - Public API

    public func getData(for url: URL) -> Result<String, ContentBlockerError> {
        logger.log("Getting data for URL: \(url.absoluteString, privacy: .public)")

        do {
            let data = try contentBlockerEngine.getData(url: url)
            logger.log("Data returned from engine: \(data, privacy: .public)")
            return .success(data)
        } catch {
            logger.error(
                "Failed to get data for URL: \(url.absoluteString, privacy: .public) - Error: \(error.localizedDescription, privacy: .public)"
            )
            return .failure(.dataRetrievalError(url, error))
        }
    }
}
