import ContentBlockerConverter
import Foundation
import OSLog
import SwiftData

/// Represents a single rule with its associated category.
public struct FilterRule {
    let rule: String
    let category: FilterListCategory?
}

// MARK: - FilterListProcessor

/// Processor that downloads, converts, and saves filter lists.
@MainActor
final class FilterListProcessor {
    /// Shared session for downloading.
    let urlSession: URLSession
    /// Converter instance.
    private let converter = ContentBlockerConverter()

    /// Init with a session (default is .shared).
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    /// Downloads data from the given URL.
    func downloadFilterList(from url: URL) async throws -> (Data, URLResponse) {
        await WebShieldLogger.shared.log("⬇️ Starting download from \(url.absoluteString)")
        let (data, response) = try await urlSession.data(from: url)

        if let httpResponse = response as? HTTPURLResponse {
            await WebShieldLogger.shared.log(
                "✅ Download completed - Status: \(httpResponse.statusCode), Size: \(data.count) bytes"
            )
        }

        return (data, response)
    }

    /// Parses raw filter rules from text.
    private func parseRules(rawText: String, defaultCategory: FilterListCategory) -> [FilterRule] {
        var rules: [FilterRule] = []
        let lines = rawText.components(separatedBy: .newlines)

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // Skip comments and empty lines
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("!") {
                continue
            }

            let rule = FilterRule(rule: trimmedLine, category: defaultCategory)
            rules.append(rule)
        }

        return rules
    }

    // MARK: - Public Main Entry

    /// Downloads, parses, converts a single filter list, then updates the SwiftData model.
    func processFilterList(
        _ filterList: FilterList
    ) async throws -> (ProcessedConversionResult, FilterListCategory) {
        guard let downloadUrl = filterList.downloadUrl,
            let url = URL(string: downloadUrl),
            let category = filterList.category
        else {
            throw NSError(
                domain: "FilterListProcessor", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid or missing URL or category"])
        }

        // 1. Download raw text and parse for metadata
        let (rawText, metadata) = try await downloadAndParseRawText(from: url)

        let filterRules = parseRules(rawText: rawText, defaultCategory: category)

        // 2. Convert with ContentBlockerConverter
        let conversionResult = await convertRules(filterRules: filterRules)

        // 3. Update SwiftData model fields
        filterList.version = metadata.version
        filterList.homepageUrl = metadata.homepage ?? filterList.homepageUrl
        filterList.standardRuleCount = conversionResult.convertedCount
        filterList.advancedRuleCount = conversionResult.advancedBlockingCount
        filterList.downloaded = true
        filterList.needsRefresh = false
        filterList.lastUpdated = Date()

        return (conversionResult, category)
    }

    // MARK: - Writing the JSON files

    /// Saves the conversion results from all lists into individual category-based JSON files
    /// and a single combined file for advanced rules.
    func saveContentBlockerFiles(
        results: [(ProcessedConversionResult, FilterListCategory)],
        directoryURL: URL
    ) async throws {
        var allAdvancedRules: [[String: Any]] = []

        // 1. Collect ALL advanced rules from all categories
        for (result, _) in results {
            if let advancedString = result.advancedBlocking,
                let advancedData = advancedString.data(using: .utf8)
            {
                do {
                    if let advancedArray = try JSONSerialization.jsonObject(with: advancedData) as? [[String: Any]] {
                        allAdvancedRules.append(contentsOf: advancedArray)
                    }
                } catch {
                    await WebShieldLogger.shared.log("Failed to parse advanced blocking JSON: \(error)")
                }
            }
        }

        // 2. Process regular rules per category (EXCLUDE .all)
        for category in FilterListCategory.allCases.filter({ $0 != .all }) {
            let fileName = "\(category.rawValue.lowercased()).json"
            let fileURL = directoryURL.appendingPathComponent(fileName)
            var regularRules: [[String: Any]] = []

            // Find regular rules for this category
            let resultsForCategory = results.filter { $0.1 == category }

            for (result, _) in resultsForCategory {
                if let convertedString = result.converted,
                    let data = convertedString.data(using: .utf8)
                {
                    do {
                        if let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                            regularRules.append(contentsOf: array)
                        }
                    } catch {
                        await WebShieldLogger.shared.log("Failed to parse regular rules for \(category): \(error)")
                    }
                }
            }

            // Write category file
            if regularRules.isEmpty {
                try writeMinimalRule(to: fileURL)
                await WebShieldLogger.shared.log("📁 Category: \(category.rawValue) - Wrote minimal rules")
            } else {
                let regularData = try JSONSerialization.data(withJSONObject: regularRules, options: [])
                try regularData.write(to: fileURL, options: .atomic)
                await WebShieldLogger.shared.log(
                    """
                    📁 Category: \(category.rawValue)
                    - File: \(fileName)
                    - Regular Rules: \(regularRules.count)
                    """)
            }
        }

        // 3. Write aggregated advanced rules
        let advancedURL = directoryURL.appendingPathComponent("advancedBlocking.json")
        if allAdvancedRules.isEmpty {
            try writeEmptyJSON(to: advancedURL)
            await WebShieldLogger.shared.log("🚀 Advanced Rules: No rules found")
        } else {
            let advancedData = try JSONSerialization.data(withJSONObject: allAdvancedRules, options: [])
            try advancedData.write(to: advancedURL, options: .atomic)
            await WebShieldLogger.shared.log(
                """
                🚀 Advanced Rules:
                - Total Advanced Rules: \(allAdvancedRules.count)
                - Saved to: advancedBlocking.json
                """)
        }
    }
    
    /// Saves the converted rules as JSON for a given category.
    /// Writes an empty `[]` file if rules are missing or cannot be parsed.
    func saveContentBlockerFile(
        result: ProcessedConversionResult,
        category: FilterListCategory,
        directoryURL: URL
    ) async throws {
        let fileURL = directoryURL.appendingPathComponent("\(category.rawValue.lowercased()).json")

        // Obtain the raw converted JSON
        guard let rawJSON = result.converted,
            let data = rawJSON.data(using: .utf8)
        else {
            // If there's no valid JSON, write a minimal rule
            try writeMinimalRule(to: fileURL)
            await WebShieldLogger.shared.log("Wrote minimal \(fileURL.lastPathComponent)")
            return
        }

        // Parse the JSON into an array of dictionaries
        do {
            let rules = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            var finalData: Data

            if let rules = rules, !rules.isEmpty {
                finalData = try JSONSerialization.data(withJSONObject: rules, options: [])
                await WebShieldLogger.shared.log("Wrote \(rules.count) regular rules to \(fileURL.lastPathComponent)")
            } else {
                // Write a minimal rule to signify an empty or default state
                let minimalRule: [[String: Any]] = [
                    [
                        "trigger": [
                            "url-filter": ".*"
                        ],
                        "action": [
                            "type": "ignore-previous-rules"
                        ],
                    ]
                ]
                finalData = try JSONSerialization.data(withJSONObject: minimalRule, options: [])
                await WebShieldLogger.shared.log("Wrote minimal \(fileURL.lastPathComponent)")
            }

            // Write to the category-specific JSON file (overwriting any existing content)
            try finalData.write(to: fileURL, options: .atomic)
        } catch {
            // If parsing fails, write a minimal rule
            try writeMinimalRule(to: fileURL)
            await WebShieldLogger.shared.log(
                "Failed to parse converted JSON for category \(category.rawValue): \(error)")
            await WebShieldLogger.shared.log("Wrote minimal \(fileURL.lastPathComponent)")
        }
    }

    // MARK: - Helper Methods

    /// Writes a minimal rule to the specified file URL.
    private func writeMinimalRule(to fileURL: URL) throws {
        let minimalRule: [[String: Any]] = [
            [
                "trigger": [
                    "url-filter": ".*"
                ],
                "action": [
                    "type": "ignore-previous-rules"
                ],
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: minimalRule, options: [])
        try data.write(to: fileURL, options: .atomic)
    }

    /// Writes an empty JSON array to the specified file URL.
    private func writeEmptyJSON(to fileURL: URL) throws {
        let empty = Data("[]".utf8)
        try empty.write(to: fileURL, options: .atomic)
    }

    // MARK: - Private Helpers

    /// Downloads the data from the URL and parses for metadata (version, homepage).
    private func downloadAndParseRawText(from url: URL) async throws -> (String, ParsedMetadata) {
        let (data, response) = try await urlSession.data(from: url)

        guard
            let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200,
            let rawText = String(data: data, encoding: .utf8)
        else {
            throw FilterListError.invalidServerResponse
        }

        let metadata = parseMetadata(from: rawText)
        return (rawText, metadata)
    }

    /// Parses metadata such as version and homepage from the content.
    private func parseMetadata(from content: String) -> ParsedMetadata {
        var version = "1.0.0"
        var homepage: String?

        for line in content.split(whereSeparator: \.isNewline) {
            // ! Version:
            if line.hasPrefix("! Version:") {
                let newVersion =
                    line
                    .dropFirst("! Version:".count)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !newVersion.isEmpty {
                    version = newVersion
                }
            }
            // ! Homepage:
            else if line.hasPrefix("! Homepage:") {
                let newHomepage =
                    line
                    .dropFirst("! Homepage:".count)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !newHomepage.isEmpty {
                    homepage = newHomepage
                }
            }

            // If both are found, no need to continue
            if homepage != nil && version != "1.0.0" {
                break
            }
        }

        return ParsedMetadata(version: version, homepage: homepage)
    }

    /// Converts filter rules using the ContentBlockerConverter.
    private func convertRules(filterRules: [FilterRule]) async -> ProcessedConversionResult {
        await WebShieldLogger.shared.log(
            "⚙️ Starting conversion of \(filterRules.count) rules"
        )

        let conversionResult = converter.convertArray(
            rules: filterRules.map { $0.rule },
            safariVersion: .safari16_4,
            optimize: false,
            advancedBlocking: true,
            advancedBlockingFormat: .json,
            progress: nil
        )

        await WebShieldLogger.shared.log(
            """
            🔄 Conversion results:
            - Total Rules: \(conversionResult.totalConvertedCount)
            - Regular Rules: \(conversionResult.convertedCount)
            - Advanced Rules: \(conversionResult.advancedBlockingConvertedCount)
            - Errors: \(conversionResult.errorsCount)
            """)

        return ProcessedConversionResult(
            converted: conversionResult.converted,
            advancedBlocking: conversionResult.advancedBlocking,
            convertedCount: conversionResult.convertedCount,
            advancedBlockingCount: conversionResult.advancedBlockingConvertedCount,
            errorsCount: conversionResult.errorsCount,
            overLimit: conversionResult.overLimit,
            message: conversionResult.message
        )
    }
    /// Helper to merge two JSON strings (arrays)
    private func mergeJSONStrings(primary: String, secondary: String) -> String {
        guard let primaryData = primary.data(using: .utf8),
            let secondaryData = secondary.data(using: .utf8)
        else {
            return primary  // Or secondary, whichever is valid
        }

        do {
            var primaryArray = try JSONSerialization.jsonObject(with: primaryData) as? [[String: Any]] ?? []
            let secondaryArray = try JSONSerialization.jsonObject(with: secondaryData) as? [[String: Any]] ?? []

            primaryArray.append(contentsOf: secondaryArray)

            let mergedData = try JSONSerialization.data(withJSONObject: primaryArray, options: [])
            return String(data: mergedData, encoding: .utf8) ?? "[]"
        } catch {
            print("Error merging JSONs: \(error)")
            return primary  // Fallback to primary
        }
    }

    /// Counts the number of rules in a JSON string.
    private func countRulesInJSON(jsonString: String?) -> Int {
        guard let jsonString = jsonString,
            let data = jsonString.data(using: .utf8)
        else {
            return 0
        }

        do {
            if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [Any] {
                return jsonArray.count
            }
        } catch {
            print("Error counting rules in JSON: \(error)")
        }

        return 0
    }

    /// Saves or updates a filter list in the SwiftData model.
    func saveFilterList(
        to context: ModelContext,
        id: String,
        name: String,
        version: String,
        description: String,
        category: FilterListCategory,
        isEnabled: Bool,
        order: Int,
        downloadUrl: String? = nil,
        homepageUrl: String? = nil,
        downloaded: Bool,
        needsRefresh: Bool
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
            existing.needsRefresh = needsRefresh
            if let sourceUrl = downloadUrl, !sourceUrl.isEmpty {
                existing.downloadUrl = sourceUrl
            }
            if let homepage = homepageUrl, !homepage.isEmpty {
                existing.homepageUrl = homepage
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
                downloadUrl: downloadUrl,
                homepageUrl: homepageUrl,
                downloaded: downloaded,
                needsRefresh: needsRefresh
            )
            newFilterList.id = id  // Ensure FilterList has an `id` property
            context.insert(newFilterList)
        }
    }
}
