import ContentBlockerConverter
import Foundation
import SwiftData

struct ProcessedConversionResult {
    let totalConvertedCount: Int
    let convertedCount: Int
    let errorsCount: Int
    let overLimit: Bool
    let converted: String?
    let advancedBlocking: [ContentBlockerRule]?
    let message: String?
}

struct Rule: Encodable, Decodable {
    let trigger: Trigger
    let action: Action

    struct Trigger: Encodable, Decodable {
        let urlFilter: String
        let urlFilterIsCaseSensitive: Bool?
        let resourceType: [String]?
        let ifDomain: [String]?
        let unlessDomain: [String]?
        let ifTopURL: [String]?
        let unlessTopURL: [String]?
        let loadType: [String]?

        // CodingKeys to match JSON keys if different from property names
        enum CodingKeys: String, CodingKey {
            case urlFilter = "url-filter"
            case urlFilterIsCaseSensitive = "url-filter-is-case-sensitive"
            case resourceType = "resource-type"
            case ifDomain = "if-domain"
            case unlessDomain = "unless-domain"
            case ifTopURL = "if-top-url"
            case unlessTopURL = "unless-top-url"
            case loadType = "load-type"
        }
    }

    struct Action: Encodable, Decodable {
        let type: String
        let selector: String?
        let subject: String?

        // CodingKeys if needed
        enum CodingKeys: String, CodingKey {
            case type, selector, subject
        }
    }
}

struct ContentBlockerRule: Codable {
    let trigger: Trigger
    let action: Action

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(trigger, forKey: .trigger)
        try container.encode(action, forKey: .action)
    }

    enum CodingKeys: String, CodingKey {
        case trigger, action
    }
}

struct Trigger: Codable {
    let urlFilter: String
    let ifDomain: [String]?
    let unlessDomain: [String]?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(urlFilter, forKey: .urlFilter)
        try container.encodeIfPresent(ifDomain, forKey: .ifDomain)
        try container.encodeIfPresent(unlessDomain, forKey: .unlessDomain)
    }

    enum CodingKeys: String, CodingKey {
        case urlFilter = "url-filter"
        case ifDomain = "if-domain"
        case unlessDomain = "unless-domain"
    }
}

struct Action: Codable {
    let type: String
    let script: String?
    let css: String?
    let scriptlet: String?
    let scriptletParam: String?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(script, forKey: .script)
        try container.encodeIfPresent(css, forKey: .css)
        try container.encodeIfPresent(scriptlet, forKey: .scriptlet)
        try container.encodeIfPresent(scriptletParam, forKey: .scriptletParam)
    }

    enum CodingKeys: String, CodingKey {
        case type, script, css, scriptlet, scriptletParam
    }
}

extension ContentBlockerRule {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        trigger = try container.decode(Trigger.self, forKey: .trigger)
        action = try container.decode(Action.self, forKey: .action)
    }
}

extension Trigger {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        urlFilter = try container.decode(String.self, forKey: .urlFilter)
        ifDomain = try container.decodeIfPresent(
            [String].self, forKey: .ifDomain)
        unlessDomain = try container.decodeIfPresent(
            [String].self, forKey: .unlessDomain)
    }
}

extension Action {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        script = try container.decodeIfPresent(String.self, forKey: .script)
        css = try container.decodeIfPresent(String.self, forKey: .css)
        scriptlet = try container.decodeIfPresent(
            String.self, forKey: .scriptlet)
        scriptletParam = try container.decodeIfPresent(
            String.self, forKey: .scriptletParam)
    }
}

@MainActor
struct FilterListProcessor {
    let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func downloadFilterList(from url: URL) async throws -> Data {
        let (data, _) = try await urlSession.data(from: url)
        return data
    }

    func downloadAndParse(
        from url: URL, id: String, name: String, existingHomepage: String? = nil
    ) async throws -> (ProcessedConversionResult, String, String?) {
        LogsView.logProcessingStep("Starting download", for: name)

        let data = try await downloadData(from: url, for: name)

        LogsView.logProcessingStep("Starting parsing", for: name)
        let rules = try await parseRules(data, for: name)
        LogsView.logProcessingStep(
            "Successfully parsed \(rules.count) rules", for: "Parser")

        // Log a sample of the rules for debugging
        if let firstRule = rules.first {
            LogsView.logProcessingStep(
                "Sample rule: \(firstRule)", for: name)
        }

        // Extract metadata but preserve existing homepage if present
        let metadata = try extractMetadata(from: data)
        let homepage = existingHomepage ?? metadata.homepage
        if let homepage = homepage {
            LogsView.logProcessingStep(
                "Using homepage: \(homepage)", for: name)
        }

        LogsView.logProcessingStep(
            "Starting conversion of \(rules.count) rules", for: name)

        // Update here to use ProcessedConversionResult
        let result = try await convertRulesToAdGuardFormat(rules, for: name)

        logConversionStatistics(from: result, for: name)

        return (result, metadata.version, metadata.homepage)
    }

    // Helper functions for better readability and error handling

    private func downloadData(from url: URL, for name: String) async throws
        -> Data
    {
        do {
            let (data, _) = try await urlSession.data(from: url)
            LogsView.logProcessingStep("Download completed", for: name)
            return data
        } catch {
            LogsView.logProcessingStep(
                "Download failed: \(error.localizedDescription)", for: name)
            throw error
        }
    }

    private func parseRules(_ data: Data, for name: String) async throws
        -> [String]
    {
        guard let content = String(data: data, encoding: .utf8) else {
            LogsView.logProcessingStep(
                "Failed to decode data as UTF-8", for: "Parser")
            throw FilterListError.invalidData
        }

        let lines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let validRules = lines.filter { !$0.isEmpty && !$0.hasPrefix("!") }

        guard !validRules.isEmpty else {
            LogsView.logProcessingStep(
                "No valid rules found after parsing", for: "Parser")
            throw FilterListError.parsingFailed
        }

        return validRules
    }

    func convertToAdGuardFormat(_ rules: [String]) async throws
        -> ProcessedConversionResult
    {
        LogsView.logProcessingStep(
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
            LogsView.logProcessingStep(
                "Conversion had \(result.errorsCount) errors", for: "Converter")
        }

        // Decode advancedBlocking into an array of ContentBlockerRule
        var advancedRules: [ContentBlockerRule] = []
        if let advancedBlockingString = result.advancedBlocking,
            let data = advancedBlockingString.data(using: .utf8)
        {
            do {
                let rules = try JSONDecoder().decode(
                    [ContentBlockerRule].self, from: data)
                advancedRules = rules
            } catch {
                LogsView.logProcessingStep(
                    "Failed to decode advancedBlocking JSON: \(error.localizedDescription)",
                    for: "Converter"
                )
            }
        }

        // Create a ProcessedConversionResult
        let processedResult = ProcessedConversionResult(
            totalConvertedCount: result.totalConvertedCount,
            convertedCount: result.convertedCount,
            errorsCount: result.errorsCount,
            overLimit: result.overLimit,
            converted: result.converted,
            advancedBlocking: advancedRules,
            message: result.message
        )

        return processedResult
    }

    private func logConversionStatistics(
        from result: ProcessedConversionResult, for name: String
    ) {
        LogsView.logConversionStatistics(
            totalConvertedCount: result.totalConvertedCount,
            convertedCount: result.convertedCount,
            errorsCount: result.errorsCount,
            overLimit: result.overLimit,
            for: name
        )
    }

    func updateFilterListRuleCounts(
        filterList: FilterList,
        result: ProcessedConversionResult  // Update type here
    ) {
        filterList.standardRuleCount = result.convertedCount
        filterList.advancedRuleCount = result.advancedBlocking?.count ?? 0
        filterList.lastUpdated = Date()
    }

    private func convertRulesToAdGuardFormat(
        _ rules: [String], for name: String
            // Update here to use ProcessedConversionResult
    ) async throws -> ProcessedConversionResult {
        do {
            let result = try await convertToAdGuardFormat(rules)
            LogsView.logProcessingStep("Conversion completed", for: name)
            return result
        } catch {
            LogsView.logProcessingStep(
                "Conversion error: \(error.localizedDescription)", for: name)
            throw error
        }
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

    func saveContentBlockerRules(
        to url: URL, conversionResults: [ProcessedConversionResult]
    ) async throws {
        let baseURL = url.deletingLastPathComponent()
        let blockerListURL = baseURL.appendingPathComponent("blockerList.json")
        let advancedBlockingURL = baseURL.appendingPathComponent(
            "advancedBlocking.json")

        LogsView.logProcessingStep(
            "Starting to write rules to \(blockerListURL.lastPathComponent) and \(advancedBlockingURL.lastPathComponent)",
            for: "FilterListProcessor"
        )

        // MARK: - Save Regular Rules
        try await saveRegularRules(
            to: blockerListURL, conversionResults: conversionResults)

        // MARK: - Save Advanced Blocking Rules
        try await saveAdvancedBlockingRules(
            to: advancedBlockingURL, conversionResults: conversionResults)

        // MARK: - Log Total Statistics
        logTotalStatistics(from: conversionResults)
    }

    private func saveRegularRules(
        to url: URL, conversionResults: [ProcessedConversionResult]
    ) async throws {
        var allRules: [Rule] = []

        for result in conversionResults {
            if let convertedString = result.converted,
                let convertedData = convertedString.data(using: .utf8)
            {
                do {
                    // Decode the JSON data into an array of dictionaries
                    if let jsonArray = try JSONSerialization.jsonObject(
                        with: convertedData, options: []) as? [[String: Any]]
                    {
                        // Convert each dictionary to a Rule and append to allRules
                        let rules = jsonArray.compactMap { ruleDict -> Rule? in
                            guard
                                let triggerDict = ruleDict["trigger"]
                                    as? [String: Any],
                                let actionDict = ruleDict["action"]
                                    as? [String: Any],
                                let trigger = try? JSONDecoder().decode(
                                    Rule.Trigger.self,
                                    from: JSONSerialization.data(
                                        withJSONObject: triggerDict)),
                                let action = try? JSONDecoder().decode(
                                    Rule.Action.self,
                                    from: JSONSerialization.data(
                                        withJSONObject: actionDict))
                            else {
                                return nil
                            }
                            return Rule(trigger: trigger, action: action)
                        }
                        allRules.append(contentsOf: rules)
                    }
                } catch {
                    LogsView.logProcessingStep(
                        "Failed to decode JSON array from string: \(error.localizedDescription)",
                        for: "FilterListProcessor"
                    )
                }
            }
        }

        guard !allRules.isEmpty else {
            LogsView.logProcessingStep(
                "No regular rules to write.", for: "FilterListProcessor")
            return
        }

        // Encode and save the rules
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let jsonData = try encoder.encode(allRules)
            try jsonData.write(to: url)
            LogsView.logProcessingStep(
                "Successfully wrote \(allRules.count) regular rules to \(url.absoluteString)",
                for: "FilterListProcessor"
            )
        } catch {
            LogsView.logProcessingStep(
                "Failed to encode or write regular rules: \(error.localizedDescription)",
                for: "FilterListProcessor"
            )
            throw error
        }
    }

    private func saveAdvancedBlockingRules(
        to url: URL, conversionResults: [ProcessedConversionResult]  // Update type here
    ) async throws {
        // 1. Extract Advanced Rules
        let advancedRules = conversionResults.flatMap {
            $0.advancedBlocking ?? []  // Access advancedBlocking directly
        }

        // 2. Handle Empty Rules Case
        guard !advancedRules.isEmpty else {
            LogsView.logProcessingStep(
                "No advanced blocking rules to write.",
                for: "FilterListProcessor"
            )
            return
        }

        // 3. Encode and Save Rules
        try await encodeAndSaveRules(advancedRules, to: url)

        // 4. Log Success
        LogsView.logProcessingStep(
            "Successfully wrote advanced blocking rules to \(url.absoluteString)",
            for: "FilterListProcessor"
        )
    }

    // Helper function to encode and save rules to a file
    private func encodeAndSaveRules(_ rules: [ContentBlockerRule], to url: URL)
        async throws
    {

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let jsonData = try encoder.encode(rules)
            try jsonData.write(to: url)
        } catch {
            LogsView.logProcessingStep(
                "Failed to encode or write advanced blocking rules: \(error.localizedDescription)",
                for: "FilterListProcessor"
            )
            throw error
        }
    }

    private func logTotalStatistics(
        from conversionResults: [ProcessedConversionResult]
    ) {
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
            """

            === Total Statistics ===
            Total rules processed: \(totalStats.0)
            Successfully converted: \(totalStats.1)
            Total errors: \(totalStats.2)
            Over limit: \(totalStats.3)
            """,
            for: "FilterListProcessor"
        )
    }
}
