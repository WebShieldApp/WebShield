import Combine
import ContentBlockerConverter
import Foundation
import SafariServices

@MainActor final class FilterListManager: ObservableObject {
    @Published private(set) var filterLists: [FilterList] = []
    @Published private(set) var isUpdating = false
    @Published var progress: Double = 0

    private let contentBlockerState: ContentBlockerState
    private let fileManager: FileManager
    private let urlSession: URLSession
    private var totalStats:
        (
            totalConvertedCount: Int, convertedCount: Int, errorsCount: Int,
            overLimit: Int
        ) = (0, 0, 0, 0)

    init(
        fileManager: FileManager = .default,
        urlSession: URLSession = .shared
    ) {
        contentBlockerState = ContentBlockerState()
        self.fileManager = fileManager
        self.urlSession = urlSession

        loadFilterLists()
        filterLists = FilterListProvider.allFilterLists
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
            filter.isSelected, forKey: "filter_\(filter.name)"
        )
    }

    private func saveLastUpdateDate(filter: FilterList) {
        UserDefaults.standard.set(
            Date(), forKey: "lastUpdateDate_\(filter.name)"
        )
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

    // todo: something is wrong
    func applyChanges() async {
        let selectedLists = filterLists.filter { $0.isSelected }
        var allRules: [[String: Any]] = []
        totalStats = (0, 0, 0, 0)  // Reset total stats
        for (_, list) in selectedLists.enumerated() {
            do {
                let data = try await self.downloadFilterList(
                    from: list.url, name: list.name
                )
                let parsed = try self.parseRules(data)
                let converted = try await self.convertToAdGuardFormat(
                    parsed)
                //                let isFirst = index == 0
                //                let isLast = index == selectedLists.count - 1
                if let newRules = try? JSONSerialization.jsonObject(
                    with: Data(converted.converted.utf8), options: [])
                    as? [[String: Any]]
                {
                    allRules.append(contentsOf: newRules)
                }
                //                try await self.writeFilterListToFile(
                //                    converted, for: list, isFirst: isFirst,
                //                    isLast: isLast
                //                )
                self.saveLastUpdateDate(filter: list)
                self.updateTotalStats(with: converted)
                self.printConversionStatistics(converted)
                //                await self.refreshAndReloadContentBlocker()
            } catch {
                print("[WS ERROR] IN APPLYING CHANGES FLMAN")
                print("Error processing filter list: \(error)")
            }
        }

        do {
            try await self.writeAllRulesToFile(allRules)
            await self.reloadContentBlocker()
            printTotalConversionStatistics()
        } catch {
            print("Error writing rules to file: \(error)")
        }

        for list in self.filterLists {
            self.saveSelectedState(filter: list)
        }

        await updateProgress(1.0)
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

    private func writeFilterListToFile(
        _ result: ConversionResult, for _: FilterList, isFirst: Bool,
        isLast: Bool
    ) async throws {
        guard
            let containerURL = fileManager.containerURL(
                forSecurityApplicationGroupIdentifier:
                    "G5S45S77DF.me.arjuna.WebShield")
        else {
            throw FilterListError.containerNotFound
        }
        print(
            "Writing to file (blockerList.json & advancedBlocking.json) in \(containerURL.absoluteString)"
        )

        try await writeRulesToFile(
            result.converted, fileName: "blockerList.json", in: containerURL,
            isFirst: isFirst, isLast: isLast
        )
        if let advanced = result.advancedBlocking {
            try await writeRulesToFile(
                advanced, fileName: "advancedBlocking.json", in: containerURL,
                isFirst: isFirst, isLast: isLast
            )
        }
    }

    private func writeRulesToFile(
        _ content: String, fileName: String, in containerURL: URL,
        isFirst: Bool, isLast: Bool
    ) async throws {
        let fileURL = containerURL.appending(path: fileName)
        var existingContent: [[String: Any]] = []

        if fileManager.fileExists(atPath: fileURL.path) {
            let data = try Data(contentsOf: fileURL)
            existingContent =
                try JSONSerialization.jsonObject(with: data, options: [])
                as? [[String: Any]] ?? []
        }

        let newContent =
            try JSONSerialization.jsonObject(
                with: Data(content.utf8), options: []
            ) as? [[String: Any]] ?? []

        if isFirst {
            existingContent = newContent
        } else {
            existingContent.append(contentsOf: newContent)
        }

        if isLast {
            let combinedData = try JSONSerialization.data(
                withJSONObject: existingContent, options: .prettyPrinted
            )
            try combinedData.write(to: fileURL, options: .atomic)
        }

        let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
        if let fileSize = attributes[.size] as? Int64, fileSize > 2_000_000 {
            print(
                "WARNING: \(fileName) size (\(fileSize) bytes) exceeds 2MB limit for Safari content blockers!"
            )
        }
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
    @MainActor
    private func updateProgress(_ newProgress: Double) async {
        progress = newProgress
    }

    func toggleFilterListSelection(id: UUID) {
        if let index = filterLists.firstIndex(where: { $0.id == id }) {
            filterLists[index].isSelected.toggle()
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

    func printTotalConversionStatistics() {
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
