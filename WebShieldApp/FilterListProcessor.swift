import ContentBlockerConverter  // Your public SafariConverterLib
import Foundation
import OSLog
import SwiftData

/// A simple struct to hold metadata parsed from filter list text.
private struct ParsedMetadata {
    var version: String
    var homepage: String?
}

/// Processor that downloads, converts, and saves filter lists.
@MainActor
final class FilterListProcessor {
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
    ///   - modelContext: The SwiftData context to save updates
    /// - Returns: A `ProcessedConversionResult` describing the results (or throws on error).
    func processFilterList(
        _ filterList: FilterList,
        modelContext: ModelContext
    ) async throws -> ProcessedConversionResult {
        guard let urlString = filterList.urlString,
            let url = URL(string: urlString)
        else {
            throw NSError(
                domain: "FilterListProcessor", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid or missing URL"])
        }

        // 1. Download raw text
        let (rawText, metadata) = try await downloadAndParseRawText(from: url)

        // 2. Convert with ContentBlockerConverter
        let conversionResult = await convertRules(rawText: rawText)

        // 3. Update SwiftData model fields: version, homepage, rule counts, etc.
        filterList.version = metadata.version
        if filterList.homepageURL == nil || filterList.homepageURL?.isEmpty == true {
            filterList.homepageURL = metadata.homepage
        }

        // "Standard" vs. "Advanced" rule counts
        filterList.standardRuleCount = conversionResult.convertedCount
        filterList.advancedRuleCount = conversionResult.advancedBlockingCount
        filterList.downloaded = true
        filterList.lastUpdated = Date()

        // 4. Save updates to SwiftData context
        try modelContext.save()

        return conversionResult
    }

    // MARK: - Writing the JSON files
    /// Saves the aggregated conversion results from all lists into `blockerList.json` + `advancedBlocking.json`.
    ///
    /// - Parameters:
    ///   - results: An array of `ProcessedConversionResult` from multiple filter lists
    ///   - directoryURL: The URL (in group container) where files should be written
    func saveContentBlockerFiles(results: [ProcessedConversionResult], directoryURL: URL) async throws {
        let blockerListURL = directoryURL.appendingPathComponent("blockerList.json")
        let advancedBlockingURL = directoryURL.appendingPathComponent("advancedBlocking.json")

        // 1. Gather all "regular" rules
        let regularRules = results.compactMap { $0.converted }  // raw JSON strings
            .flatMap { jsonString -> [[String: Any]] in
                if let data = jsonString.data(using: .utf8),
                    let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
                {
                    return array
                }
                return []
            }

        // 2. If no regular rules, write an empty array "[]"
        if regularRules.isEmpty {
            let empty = "[]".data(using: .utf8)!
            try empty.write(to: blockerListURL, options: .atomic)
            LogsView.addLog("Wrote empty blockerList.json to \(blockerListURL.path)")
        } else {
            // Write combined JSON
            let data = try JSONSerialization.data(withJSONObject: regularRules, options: .prettyPrinted)
            try data.write(to: blockerListURL, options: .atomic)
            LogsView.addLog("Wrote \(regularRules.count) regular rules to \(blockerListURL.path)")
        }

        // 3. Gather all "advanced" rules
        let advancedRules = results.compactMap { $0.advancedBlocking }  // raw JSON strings
            .flatMap { jsonString -> [[String: Any]] in
                if let data = jsonString.data(using: .utf8),
                    let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
                {
                    return array
                }
                return []
            }

        if advancedRules.isEmpty {
            // Write an empty file or skip. We'll write empty for consistency.
            let empty = "[]".data(using: .utf8)!
            try empty.write(to: advancedBlockingURL, options: .atomic)
            LogsView.addLog("No advanced rules. Wrote empty advancedBlocking.json to \(advancedBlockingURL.path)")
        } else {
            let data = try JSONSerialization.data(withJSONObject: advancedRules, options: .prettyPrinted)
            try data.write(to: advancedBlockingURL, options: .atomic)
            LogsView.addLog("Wrote \(advancedRules.count) advanced rules to \(advancedBlockingURL.path)")
        }
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

// MARK: - Data Structures for Simpler Return Values

/// Simple container for the results of a single filter list conversion
struct ProcessedConversionResult {
    /// The regular JSON string (Safari content blocker format)
    let converted: String?
    /// The advanced blocking JSON string (if any)
    let advancedBlocking: String?
    /// Count of standard rules
    let convertedCount: Int
    /// Count of advanced rules
    let advancedBlockingCount: Int
    /// Number of errors encountered
    let errorsCount: Int
    /// If the converter found the rules were over the size limit
    let overLimit: Bool
    /// A human-readable message about the conversion
    let message: String?
}
