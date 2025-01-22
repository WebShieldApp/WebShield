@preconcurrency import ContentBlockerConverter
import Foundation
import OSLog
import SwiftData

/// Processor that downloads, converts, and saves filter lists.
@MainActor
final class FilterListProcessor: Sendable {
    /// Shared session for downloading.
    let urlSession: URLSession

    /// We can re-use one converter instance or instantiate a new one per list.
    private let converter = ContentBlockerConverter()

    /// Init with a session (default is .shared).
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    // MARK: - Public Main Entry
    /// Downloads, parses, converts a single filter list, then updates the SwiftData model.
    ///
    /// - Parameters:
    ///   - filterList: The SwiftData model object representing this filter
    /// - Returns: A tuple containing `ProcessedConversionResult` and the `FilterListCategory`.
    func processFilterList(
        _ filterList: FilterList
    ) async throws -> (ProcessedConversionResult, FilterListCategory) {  // Return category
        guard let urlString = filterList.urlString,
            let url = URL(string: urlString),
            let category = filterList.category
        else {
            throw NSError(
                domain: "FilterListProcessor", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid or missing URL or category"])
        }

        // 1. Download raw text
        let (rawText, metadata) = try await downloadAndParseRawText(from: url)

        // 2. Convert with ContentBlockerConverter
        let conversionResult = await convertRules(rawText: rawText)

        // 3. Update SwiftData model fields
        filterList.version = metadata.version
        filterList.homepageURL = metadata.homepage ?? filterList.homepageURL
        filterList.standardRuleCount = conversionResult.convertedCount
        filterList.advancedRuleCount = conversionResult.advancedBlockingCount
        filterList.downloaded = true
        filterList.lastUpdated = Date()

        // 4. Save to category-specific JSON file immediately after conversion
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Identifiers.groupID) {
            try await saveContentBlockerFile(result: conversionResult, category: category, directoryURL: groupURL)
            LogsView.addLog("Saved content blocker file for category: \(category.rawValue)")
        } else {
            LogsView.addLog("Failed to get group container URL.")
        }

        return (conversionResult, category)  // Return result and category
    }

    // MARK: - Writing the JSON files
    /// Saves the conversion results from all lists into individual category-based JSON files
    /// and a single combined file for advanced rules.
    func saveContentBlockerFiles(results: [(ProcessedConversionResult, FilterListCategory)], directoryURL: URL)
        async throws
    {
        // Group results by category
        let groupedResults = Dictionary(grouping: results, by: { $0.1 })

        // Separate storage for advanced rules
        var allAdvancedRules: [[String: Any]] = []

        // Save each category's regular rules to a separate file and collect advanced rules
        for (category, results) in groupedResults {
            // Skip saving a file for the "all" category
            guard category != .all else { continue }

            let fileName = "\(category.rawValue.lowercased()).json"
            let fileURL = directoryURL.appendingPathComponent(fileName)

            // Combine regular rules for this category
            let regularRules = results.compactMap { $0.0.converted }
                .flatMap { jsonString -> [[String: Any]] in
                    if let data = jsonString.data(using: .utf8),
                        let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
                    {
                        return array
                    }
                    return []
                }

            // Collect advanced rules for this category
            let advancedRules = results.compactMap { $0.0.advancedBlocking }
                .flatMap { jsonString -> [[String: Any]] in
                    if let data = jsonString.data(using: .utf8),
                        let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
                    {
                        return array
                    }
                    return []
                }
            allAdvancedRules.append(contentsOf: advancedRules)

            // Write regular rules to category file
            if regularRules.isEmpty {
                let empty = "[]".data(using: .utf8)!
                try? empty.write(to: fileURL, options: .atomic)  // Use try? to ignore error if writing empty fails
                LogsView.addLog("Wrote empty \(fileName)")
            } else {
                let data = try JSONSerialization.data(withJSONObject: regularRules, options: .prettyPrinted)
                if let existingData = try? Data(contentsOf: fileURL),
                    let existingRules = try? JSONSerialization.jsonObject(with: existingData) as? [[String: Any]]
                {
                    // Merge with existing rules
                    let combinedRules = existingRules + regularRules
                    let combinedData = try JSONSerialization.data(
                        withJSONObject: combinedRules, options: .prettyPrinted)
                    try combinedData.write(to: fileURL, options: .atomic)
                    LogsView.addLog(
                        "Appended \(regularRules.count) regular rules to \(fileName), total: \(combinedRules.count)")
                } else {
                    // Write new rules
                    try data.write(to: fileURL, options: .atomic)
                    LogsView.addLog("Wrote \(regularRules.count) regular rules to \(fileName)")
                }
            }
        }

        // Write all advanced rules to a single file
        let advancedBlockingURL = directoryURL.appendingPathComponent("advancedBlocking.json")
        if allAdvancedRules.isEmpty {
            let empty = "[]".data(using: .utf8)!
            try? empty.write(to: advancedBlockingURL, options: .atomic)  // Use try? to ignore error if writing empty fails
            LogsView.addLog("Wrote empty advancedBlocking.json")
        } else {
            let data = try JSONSerialization.data(withJSONObject: allAdvancedRules, options: .prettyPrinted)
            try data.write(to: advancedBlockingURL, options: .atomic)
            LogsView.addLog("Wrote \(allAdvancedRules.count) advanced rules to advancedBlocking.json")
        }
    }

    // MARK: - Writing the JSON files (for individual filter list)
    func saveContentBlockerFile(result: ProcessedConversionResult, category: FilterListCategory, directoryURL: URL)
        async throws
    {
        // Skip saving for the "all" category
        guard category != .all else { return }

        let fileName = "\(category.rawValue.lowercased()).json"
        let fileURL = directoryURL.appendingPathComponent(fileName)

        // Write regular rules
        if let regularRulesJSON = result.converted,
            let regularRulesData = regularRulesJSON.data(using: .utf8),
            let regularRules = try? JSONSerialization.jsonObject(with: regularRulesData) as? [[String: Any]]
        {
            if regularRules.isEmpty {
                let empty = "[]".data(using: .utf8)!
                try empty.write(to: fileURL, options: .atomic)
                LogsView.addLog("Wrote empty \(fileName)")
            } else {
                let data = try JSONSerialization.data(withJSONObject: regularRules, options: .prettyPrinted)
                try data.write(to: fileURL, options: .atomic)
                LogsView.addLog("Wrote \(regularRules.count) regular rules to \(fileName)")
            }
        }

        // Write advanced rules (if any)
        //        if let advancedRulesJSON = result.advancedBlocking,
        //            let advancedRulesData = advancedRulesJSON.data(using: .utf8),
        //            let advancedRules = try? JSONSerialization.jsonObject(with: advancedRulesData) as? [[String: Any]]
        //        {
        //            if !advancedRules.isEmpty {
        //                let advancedFileName = "\(category.rawValue.lowercased())_advanced.json"
        //                let advancedFileURL = directoryURL.appendingPathComponent(advancedFileName)
        //                let data = try JSONSerialization.data(withJSONObject: advancedRules, options: .prettyPrinted)
        //                try data.write(to: advancedFileURL, options: .atomic)
        //                LogsView.addLog("Wrote \(advancedRules.count) advanced rules to \(advancedFileName)")
        //            }
        //        }
    }

    // MARK: - Private Helpers

    /// Downloads the data from the URL and parses for metadata (version, homepage).
    private func downloadAndParseRawText(from url: URL) async throws -> (rawText: String, metadata: ParsedMetadata) {
        let (data, response) = try await urlSession.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(
                domain: "FilterListProcessor", code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
        }
        guard let rawText = String(data: data, encoding: .utf8) else {
            throw NSError(
                domain: "FilterListProcessor", code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Failed to decode data as UTF-8"])
        }

        // parse metadata
        let meta = parseMetadata(from: rawText)
        return (rawText, meta)
    }

    /// Parse lines like `! Version:` or `! Homepage:` from the raw text.
    private func parseMetadata(from content: String) -> ParsedMetadata {
        var version = "1.0.0"
        var homepage: String? = nil

        // Example: we look for lines with "! Version:" or "! Homepage:"
        content.enumerateLines { line, stop in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("! Version:") {
                let v = trimmed.replacingOccurrences(of: "! Version:", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !v.isEmpty { version = v }
            } else if trimmed.hasPrefix("! Homepage:") {
                let h = trimmed.replacingOccurrences(of: "! Homepage:", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !h.isEmpty { homepage = h }
            }
        }

        return ParsedMetadata(version: version, homepage: homepage)
    }

    /// Converts lines using `ContentBlockerConverter`.
    /// Returns a `ProcessedConversionResult` with separate "converted" JSON and "advancedBlocking" JSON.
    private func convertRules(rawText: String) async -> ProcessedConversionResult {
        // 1. Filter lines, ignoring blank lines or those starting with "!"
        let lines = rawText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.hasPrefix("!") }

        // 2. Run the converter
        let result = converter.convertArray(
            rules: lines,
            safariVersion: .safari16_4,
            optimize: true,
            advancedBlocking: true,
            advancedBlockingFormat: .json
        )

        // "result.converted" is the final Safari rules JSON
        // "result.advancedBlocking" is the advanced JSON if any
        // "result.totalConvertedCount" etc. are stats

        // Build a local struct capturing what we need
        return ProcessedConversionResult(
            converted: result.converted,
            advancedBlocking: result.advancedBlocking,
            convertedCount: result.convertedCount,
            advancedBlockingCount: {
                // decode advancedBlocking to count items
                if let advString = result.advancedBlocking,
                    let data = advString.data(using: .utf8),
                    let arr = try? JSONSerialization.jsonObject(with: data) as? [Any]
                {
                    return arr.count
                }
                return 0
            }(),
            errorsCount: result.errorsCount,
            overLimit: result.overLimit,
            message: result.message
        )
    }

    func downloadFilterList(from url: URL) async throws -> Data {
        // Use whichever URLSession you have in FilterListProcessor
        let (data, _) = try await urlSession.data(from: url)
        return data
    }

    func saveFilterList(
        to context: ModelContext,
        id: String,
        name: String,
        version: String,
        description: String,
        category: FilterListCategory,
        isEnabled: Bool,
        order: Int,
        urlString: String? = nil,
        homepageURL: String? = nil,
        downloaded: Bool
    ) {
        // 1. Fetch if it already exists
        let fetchDescriptor = FetchDescriptor<FilterList>(
            predicate: #Predicate { $0.id == id }
        )

        if let existing = try? context.fetch(fetchDescriptor).first {
            // 2a. Update it
            existing.name = name
            existing.version = version
            existing.desc = description
            existing.categoryString = category.rawValue
            existing.isEnabled = isEnabled
            existing.order = order
            existing.downloaded = downloaded
            if let sourceUrl = urlString, !sourceUrl.isEmpty {
                existing.urlString = sourceUrl
            }
            if let homepage = homepageURL, !homepage.isEmpty {
                existing.homepageURL = homepage
            }
        } else {
            // 2b. Create a new one
            let newFilterList = FilterList(
                name: name,
                version: version,
                desc: description,
                category: category,
                isEnabled: isEnabled,
                order: order,
                urlString: urlString,
                homepageURL: homepageURL,
                downloaded: downloaded
            )
            newFilterList.id = id  // if FilterList has an `id` property
            context.insert(newFilterList)
        }
    }

}
