import ContentBlockerConverter
import Foundation
import SwiftData

struct FilterListProcessor {
    let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func downloadFilterList(from url: URL) async throws -> Data {
        let (data, _) = try await urlSession.data(from: url)
        return data
    }

    func downloadAndParse(from url: URL, id: String, name: String, existingHomepage: String? = nil) async throws
        -> (ConversionResult, String, String?)
    {
        await LogsView.logProcessingStep("Starting download", for: name)

        let (data, _) = try await urlSession.data(from: url)
        await LogsView.logProcessingStep("Download completed", for: name)

        await LogsView.logProcessingStep("Starting parsing", for: name)
        let rules = try await parseRules(data)

        // Log a sample of the rules for debugging
        if let firstRule = rules.first {
            await LogsView.logProcessingStep(
                "Sample rule: \(firstRule)", for: name)
        }

        // Extract metadata but preserve existing homepage if present
        let metadata = try extractMetadata(from: data)
        let homepage = existingHomepage ?? metadata.homepage
        if let homepage = homepage {
            await LogsView.logProcessingStep(
                "Using homepage: \(homepage)", for: name)
        }

        await LogsView.logProcessingStep(
            "Starting conversion of \(rules.count) rules", for: name)
        do {
            let result = try await convertToAdGuardFormat(rules)
            await LogsView.logProcessingStep("Conversion completed", for: name)

            await LogsView.logConversionStatistics(
                totalConvertedCount: result.totalConvertedCount,
                convertedCount: result.convertedCount,
                errorsCount: result.errorsCount,
                overLimit: result.overLimit,
                for: name
            )

            return (result, metadata.version, metadata.homepage)
        } catch {
            await LogsView.logProcessingStep(
                "Conversion error: \(error.localizedDescription)", for: name)
            throw error
        }
    }

    func parseRules(_ data: Data) async throws -> [String] {
        guard let content = String(data: data, encoding: .utf8) else {
            await LogsView.logProcessingStep(
                "Failed to decode data as UTF-8", for: "Parser")
            throw FilterListError.invalidData
        }

        // Split content into lines and trim whitespace
        let lines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        // Keep only non-empty lines and actual rules (not comments)
        let validRules = lines.filter { line in
            !line.isEmpty && !line.hasPrefix("!")
        }

        guard !validRules.isEmpty else {
            await LogsView.logProcessingStep(
                "No valid rules found after parsing", for: "Parser")
            throw FilterListError.parsingFailed
        }

        await LogsView.logProcessingStep(
            "Successfully parsed \(validRules.count) rules", for: "Parser")
        return validRules
    }

    func convertToAdGuardFormat(_ rules: [String]) async throws
        -> ConversionResult
    {
        await LogsView.logProcessingStep(
            "Converting rules with ContentBlockerConverter", for: "Converter")
        let converter = ContentBlockerConverter()
        let result = converter.convertArray(
            rules: rules,
            safariVersion: .safari16_4,
            optimize: true,
            advancedBlocking: true,
            advancedBlockingFormat: .json
        )

        if result.errorsCount > 0 {
            await LogsView.logProcessingStep(
                "Conversion had \(result.errorsCount) errors", for: "Converter")
        }

        return result
    }

    func extractMetadata(from data: Data) throws -> (
        version: String, homepage: String?
    ) {
        guard let content = String(data: data, encoding: .utf8) else {
            throw FilterListError.invalidData
        }

        var version = "1.0.0"
        var homepage: String? = nil

        for line in content.components(separatedBy: .newlines) {
            let trimmedLine = line.trimmingCharacters(
                in: .whitespacesAndNewlines)
            if trimmedLine.hasPrefix("! Version:") {
                let extractedVersion = trimmedLine.replacingOccurrences(
                    of: "! Version:", with: ""
                ).trimmingCharacters(in: .whitespaces)
                if !extractedVersion.isEmpty {
                    version = extractedVersion
                }
            } else if trimmedLine.hasPrefix("! Homepage:") {
                homepage = trimmedLine.replacingOccurrences(
                    of: "! Homepage:", with: ""
                ).trimmingCharacters(in: .whitespaces)
            }
        }

        return (version, homepage)
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
        homepageURL: String? = nil
    ) {
        let fetchDescriptor = FetchDescriptor<FilterList>(
            predicate: #Predicate { $0.id == id })
        if let filterList = try? context.fetch(fetchDescriptor).first {
            filterList.name = name
            filterList.version = version
            filterList.desc = description
            filterList.categoryString = category.rawValue
            filterList.isEnabled = isEnabled
            filterList.order = order
            if let homepageURL = homepageURL, !homepageURL.isEmpty {
                filterList.homepageURL = homepageURL
            }
        } else {
            let filterList = FilterList(
                name: name,
                version: version,
                desc: description,
                category: category,
                isEnabled: isEnabled,
                order: order,
                homepageURL: homepageURL
            )
            context.insert(filterList)
        }
    }

    @MainActor
    func saveContentBlockerRules(
        to url: URL, conversionResults: [ConversionResult]
    ) throws {
        let baseURL = url.deletingLastPathComponent()
        let blockerListURL = baseURL.appendingPathComponent("blockerList.json")
        let advancedBlockingURL = baseURL.appendingPathComponent(
            "advancedBlocking.json")

        LogsView.logProcessingStep(
            "Starting to write rules to \(blockerListURL.lastPathComponent) and \(advancedBlockingURL.lastPathComponent)",
            for: "System"
        )

        // Save regular rules
        let mergedRules: [String] = conversionResults.compactMap {
            $0.converted
        }
        let jsonData = try JSONEncoder().encode(mergedRules)
        try jsonData.write(to: blockerListURL)
        LogsView.logProcessingStep(
            "Successfully wrote \(mergedRules.count) rules to \(blockerListURL.lastPathComponent)",
            for: "System"
        )

        // Save advanced blocking rules
        let advancedRules: [String] = conversionResults.compactMap {
            $0.advancedBlocking
        }
        if !advancedRules.isEmpty {
            let advancedJsonData = try JSONEncoder().encode(advancedRules)
            try advancedJsonData.write(to: advancedBlockingURL)
            LogsView.logProcessingStep(
                "Successfully wrote \(advancedRules.count) advanced rules to \(advancedBlockingURL.lastPathComponent)",
                for: "System"
            )
        } else {
            LogsView.logProcessingStep(
                "No advanced rules to write",
                for: "System"
            )
        }

        // Log total statistics
        let totalStats = conversionResults.reduce((0, 0, 0, false)) {
            result, current in
            (
                result.0 + current.totalConvertedCount,
                result.1 + current.convertedCount,
                result.2 + current.errorsCount,
                result.3 || current.overLimit
            )
        }

        LogsView.logProcessingStep(
            "\n=== Total Statistics ===\n"
                + "Total rules processed: \(totalStats.0)\n"
                + "Successfully converted: \(totalStats.1)\n"
                + "Total errors: \(totalStats.2)\n"
                + "Over limit: \(totalStats.3)",
            for: "System"
        )
    }

    @MainActor
    func updateFilterListRuleCounts(
        filterList: FilterList,
        result: ConversionResult
    ) {
        filterList.standardRuleCount = result.convertedCount
        filterList.advancedRuleCount =
            result.advancedBlocking?.components(separatedBy: ",").count ?? 0
        filterList.lastUpdated = Date()
    }
}
