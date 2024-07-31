import Combine
@preconcurrency import ContentBlockerConverter
import Foundation
import SafariServices

@MainActor
final class FilterListManager: ObservableObject {
    @Published private(set) var filterLists: [FilterList] = FilterListProvider
        .allFilterLists
    @Published private(set) var isUpdating = false
    @Published var progress: Double = 0

    private let contentBlockerState: ContentBlockerState
    private let fileManager: FileManager
    private let urlSession: URLSession
    private var totalStats: TotalStats = .init()

    init(
        fileManager: FileManager = .default,
        urlSession: URLSession = .shared
    ) {
        self.contentBlockerState = ContentBlockerState()
        self.fileManager = fileManager
        self.urlSession = urlSession

        loadFilterLists()
        if checkSelectedStateForAnyFilter() {
            loadSelectedState()
        }
    }

    private func checkSelectedStateForAnyFilter() -> Bool {
        return filterLists.contains {
            UserDefaults.exists(key: "filter_\($0.name)")
        }
    }

    private func loadSelectedState() {
        let defaults = UserDefaults.standard
        for index in filterLists.indices {
            filterLists[index].isSelected = defaults.bool(
                forKey: "filter_\(filterLists[index].name)")
        }
    }

    private func saveSelectedState(filter: FilterList) {
        UserDefaults.standard.set(
            filter.isSelected, forKey: "filter_\(filter.name)")
    }

    private func saveLastUpdateDate(filter: FilterList) {
        UserDefaults.standard.set(
            Date(), forKey: "lastUpdateDate_\(filter.name)")
    }

    func getLastUpdateDate(filter: FilterList) -> String {
        let defaults = UserDefaults.standard
        guard
            let date = defaults.object(forKey: "lastUpdateDate_\(filter.name)")
                as? Date
        else {
            return "Never Updated!"
        }
        let df = DateFormatter()
        df.dateStyle = .short
        return df.string(from: date)
    }

    func isSelected(_ filterList: FilterList) -> Bool {
        return filterLists.first { $0.id == filterList.id }?.isSelected ?? false
    }

    func setSelection(for filterList: FilterList, isSelected: Bool) {
        if let index = filterLists.firstIndex(where: { $0.id == filterList.id })
        {
            filterLists[index].isSelected = isSelected
            objectWillChange.send()
        }
    }

    func applyChanges() async {
        let selectedLists = filterLists.filter { $0.isSelected }
        var allRules: [[String: Any]] = []
        totalStats = .init()  // Reset total stats

        // Process selected filter lists concurrently
        await withTaskGroup(of: (ConversionResult, FilterList).self) { group in
            for list in selectedLists {
                group.addTask {
                    do {
                        let data = try await self.downloadFilterList(
                            from: list.url, name: list.name)
                        let parsed = try await self.parseRules(data)
                        let converted = try await self.convertToAdGuardFormat(
                            parsed)
                        return (converted, list)
                    } catch {
                        await self.logMessage(
                            "Error processing filter list: \(error)")
                        return (
                            ConversionResult(
                                entries: [],
                                limit: 0,
                                errorsCount: 0,
                                message: ""
                            ),
                            list
                        )
                    }

                }
            }

            for await (converted, list) in group {
                if let newRules = try? JSONSerialization.jsonObject(
                    with: Data(converted.converted.utf8), options: [])
                    as? [[String: Any]]
                {
                    allRules.append(contentsOf: newRules)
                }

                self.saveLastUpdateDate(filter: list)
                self.updateTotalStats(with: converted)
                self.printConversionStatistics(converted)
            }
        }

        do {
            try await writeAllRulesToFile(allRules)
            await reloadContentBlocker()
            printTotalConversionStatistics()
        } catch {
            logMessage("Error writing rules to file: \(error)")
        }

        for list in filterLists {
            saveSelectedState(filter: list)
        }
    }

    private func updateTotalStats(with result: ConversionResult) {
        totalStats.totalConvertedCount += result.totalConvertedCount
        totalStats.convertedCount += result.convertedCount
        totalStats.errorsCount += result.errorsCount
        totalStats.overLimit += result.overLimit ? 1 : 0
    }

    private func downloadFilterList(from url: URL, name: String) async throws
        -> Data
    {
        print(
            "Downloading Filter List: \(name) from URL: \(url.absoluteString)")
        let (data, _) = try await urlSession.data(from: url)
        return data
    }

    private func convertToAdGuardFormat(_ rules: [String]) async throws
        -> ConversionResult
    {
        print("Converting to AdGuard format...")
        return ContentBlockerConverter().convertArray(
            rules: rules,
            safariVersion: .safari16_4,
            optimize: true,
            advancedBlocking: true,
            advancedBlockingFormat: .json
        )
    }

    private func writeAllRulesToFile(_ rules: [[String: Any]]) async throws {
        guard
            let containerURL = fileManager.containerURL(
                forSecurityApplicationGroupIdentifier:
                    "G5S45S77DF.me.arjuna.WebShield")
        else {
            throw FilterListError.containerNotFound
        }

        let fileURL = containerURL.appending(path: "blockerList.json")
        let data = try JSONSerialization.data(
            withJSONObject: rules, options: .prettyPrinted)
        try data.write(to: fileURL, options: .atomic)

        let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
        if let fileSize = attributes[.size] as? Int64, fileSize > 2_000_000 {
            print(
                "WARNING: blockerList.json size (\(fileSize) bytes) exceeds 2MB limit for Safari content blockers!"
            )
        }
    }

    private func loadFilterLists() {
        filterLists = FilterListProvider.allFilterLists
    }

    private func parseRules(_ data: Data) throws -> [String] {
        print("Parsing rules...")
        guard let content = String(data: data, encoding: .utf8) else {
            throw FilterListError.invalidData
        }

        return content.components(separatedBy: .newlines)
            .filter { !$0.hasPrefix("!") && !$0.hasPrefix("[") && !$0.isEmpty }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    private func printTotalConversionStatistics() {
        print(
            """
            Total conversion statistics:
            - Total converted count: \(totalStats.totalConvertedCount)
            - Converted count: \(totalStats.convertedCount)
            - Errors count: \(totalStats.errorsCount)
            - Lists over limit: \(totalStats.overLimit)
            """)
    }

    private func printConversionStatistics(_ result: ConversionResult) {
        print(
            """
            Conversion statistics:
            - Total converted count: \(result.totalConvertedCount)
            - Converted count: \(result.convertedCount)
            - Errors count: \(result.errorsCount)
            - Over limit: \(result.overLimit)
            """)
    }

    private func reloadContentBlocker() async {
        await contentBlockerState.reloadContentBlocker()
    }

    func logMessage(_ message: String) {
        var logs =
            UserDefaults.standard.array(forKey: "logs") as? [String] ?? []
        logs.append("\(Date()): \(message)")
        UserDefaults.standard.set(logs, forKey: "logs")
    }

    func getLogs() -> [String] {
        return UserDefaults.standard.array(forKey: "logs") as? [String] ?? []
    }
}
