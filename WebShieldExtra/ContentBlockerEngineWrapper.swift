//
//  ContentBlockerEngineWrapper.swift
//  WebShieldScripts
//
//  Created by Arjun on 2024-07-13.
//

@preconcurrency import ContentBlockerEngine
import Foundation
import os.log

final class ContentBlockerEngineWrapper: Sendable {
    private let contentBlockerEngine: ContentBlockerEngine
    static let shared = ContentBlockerEngineWrapper()
    private let logger = Logger(
        subsystem: "me.arjuna.WebShield",
        category: "ContentBlockerEngineWrapper")

    private init() {
        let requiredPart: String = "G5S45S77DF.me.arjuna.WebShield"
        let advancedBlockingURL =
            ContentBlockerEngineWrapper.getAdvancedBlockingURL(
                forGroupIdentifier: requiredPart)

        // Log the URL
        logger.log(
            "advancedBlocking.json URL: \(advancedBlockingURL.absoluteString, privacy: .public)"
        )

        // Load and parse JSON, or use empty rules as a fallback
        let json = ContentBlockerEngineWrapper.loadJSON(
            fromURL: advancedBlockingURL, logger: logger)

        // Attempt to create the engine or log an error
        self.contentBlockerEngine =
            ContentBlockerEngineWrapper.createContentBlockerEngine(
                withJSON: json, logger: logger)
    }

    // Helper method to get the URL for advancedBlocking.json
    private static func getAdvancedBlockingURL(
        forGroupIdentifier identifier: String
    )
        -> URL
    {
        guard
            let url = FileManager.default
                .containerURL(
                    forSecurityApplicationGroupIdentifier: identifier)?
                .appending(
                    path: "advancedBlocking.json",
                    directoryHint: URL.DirectoryHint.notDirectory
                )
        else {
            fatalError(
                "Could not construct URL for advancedBlocking.json")
        }
        return url
    }

    // Helper method to load and parse JSON from a file
    private static func loadJSON(fromURL url: URL, logger: Logger) -> String {
        logger.log("Attempting to read advancedBlocking.json")

        // Check if the file exists
        let fileExists = FileManager.default.fileExists(atPath: url.path)
        logger.log(
            "advancedBlocking.json exists at \(url.path, privacy: .public): \(fileExists, privacy: .public)"
        )

        // Get file attributes for debugging
        if let attributes = try? FileManager.default.attributesOfItem(
            atPath: url.path)
        {
            logger.log("File attributes: \(attributes, privacy: .public)")
        }

        guard fileExists else {
            logger.error(
                "Error: advancedBlocking.json does not exist at \(url.path, privacy: .public)"
            )

            return "[]"  // Fallback: empty rules
        }

        // Simplified file reading for debugging (bypassing potential String encoding issues)
        if let data = try? Data(contentsOf: url),
            let loadedJson = String(data: data, encoding: .utf8)
        {
            logger.debug("Successfully loaded advanced blocking rules")
            return loadedJson
        } else {
            logger.error("Failed to read or decode advancedBlocking.json")
            return "[]"  // Fallback to empty rules
        }
    }

    // Helper method to create the ContentBlockerEngine
    private static func createContentBlockerEngine(
        withJSON json: String, logger: Logger
    ) -> ContentBlockerEngine {
        do {
            logger.log("Attempting to create ContentBlockerEngine")
            let engine = try ContentBlockerEngine(json)
            logger.log("ContentBlockerEngine initialized successfully")
            return engine
        } catch {
            logger.error(
                "Failed to initialize content blocker: \(error.localizedDescription, privacy: .public)"
            )
            // Fallback to empty rules
            do {
                let engine = try ContentBlockerEngine("[]")
                logger.warning(
                    "ContentBlockerEngine initialized with empty rules as fallback"
                )
                return engine
            } catch {
                fatalError(
                    "Failed to initialize content blocker with empty rules: \(error.localizedDescription)"
                )
            }
        }
    }

    public func getData(url: URL) -> String? {
        // Ensure ContentBlockerEngine is initialized
        let engine = contentBlockerEngine

        logger.log(
            "Getting data for URL: \(url.absoluteString, privacy: .public)")

        do {
            let data = try engine.getData(url: url)
            logger.log(
                "Data returned from engine: \(data, privacy: .public)")
            return data
        } catch {
            logger.error(
                "Failed to get data for URL: \(url.absoluteString, privacy: .public) - Error: \(error.localizedDescription, privacy: .public)"
            )
            return nil
        }
    }
}
