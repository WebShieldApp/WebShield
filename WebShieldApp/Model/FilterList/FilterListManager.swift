//
//  FilterListManager.swift
//  WebShieldApp
//

import Combine
@preconcurrency import ContentBlockerConverter
import Foundation
import SafariServices

@MainActor
final class FilterListManager: ObservableObject {
    @Published private(set) var filterLists: [FilterList] = []
    @Published private(set) var isUpdating = false
    @Published var progress: Double = 0.0

    private let contentBlockerState: ContentBlockerState
    private let fileManager: FileManager
    let urlSession: URLSession
    private var totalStats: TotalStats = .init()

    private let customFilterListsKey = "customFilterLists"
    private var customFilterLists: [FilterList] = []
    @Published var hasUnsavedChanges: Bool = false
    private var initialSelectedStates: [UUID: Bool] = [:]

    // Add this to hold subscriptions
    private var cancellables = Set<AnyCancellable>()

    init(
        fileManager: FileManager = .default,
        urlSession: URLSession = .shared
    ) {
        self.contentBlockerState = ContentBlockerState()
        self.fileManager = fileManager
        self.urlSession = urlSession

        checkAndCreateGroupFolder()
        loadFilterLists()

        loadSelectedState()
        checkAndCreateBlockerList()
        Logger.clearLogs()

        // Initialize initialSelectedStates
        for filterList in filterLists {
            initialSelectedStates[UUID(uuidString: filterList.id)!] =
                filterList.isSelected
        }
    }

    private func checkSelectedStateForAnyFilter() -> Bool {
        return filterLists.contains {
            UserDefaults.exists(key: "filter_\($0.name)")
        }
    }

    // Load custom filter lists from UserDefaults
    private func loadCustomFilterLists() {
        guard
            let data = UserDefaults.standard.data(forKey: customFilterListsKey),
            let decoded = try? JSONDecoder().decode(
                [FilterList].self, from: data)
        else {
            return
        }
        customFilterLists = decoded
        filterLists.append(contentsOf: customFilterLists)
    }

    // Save custom filter lists to UserDefaults
    private func saveCustomFilterLists() {
        if let encoded = try? JSONEncoder().encode(customFilterLists) {
            UserDefaults.standard.set(encoded, forKey: customFilterListsKey)
        }
    }

    func removeCustomFilterList(_ filterList: FilterList) {
        guard filterList.category == .custom else { return }
        if let index = filterLists.firstIndex(of: filterList) {
            filterLists.remove(at: index)
        }
        if let customIndex = customFilterLists.firstIndex(of: filterList) {
            customFilterLists.remove(at: customIndex)
        }
        saveCustomFilterLists()
    }

    // Add new custom filter lists
    func addCustomFilterLists(urls: [URL]) {
        for url in urls {
            let name = url.lastPathComponent
            let newFilterList = FilterList(
                name: name,
                url: url,
                category: .custom,
                isSelected: true,
                description: "Custom filter list imported by user.",
                isAdGuardAnnoyancesList: false
            )
            customFilterLists.append(newFilterList)
            filterLists.append(newFilterList)
        }
        saveCustomFilterLists()
    }

    // Move Custom Filter List
    func moveCustomFilterList(fromOffsets: IndexSet, toOffset: Int) {
        guard fromOffsets.first != nil else { return }
        let originalIndex = fromOffsets.first!
        let destinationIndex = toOffset
        if originalIndex < destinationIndex {
            filterLists.move(
                fromOffsets: fromOffsets, toOffset: destinationIndex - 1)
        } else {
            filterLists.move(
                fromOffsets: fromOffsets, toOffset: destinationIndex)
        }
        // Update customFilterLists accordingly if needed
        saveCustomFilterLists()
    }

    // Remove Custom Filter List
    func removeCustomFilterList(
        at offsets: IndexSet, in category: FilterListCategory
    ) {
        guard category == .custom else { return }
        let customIndices = filterLists.enumerated().filter {
            $0.element.category == .custom
        }.map { $0.offset }
        let indicesToRemove = offsets.map { customIndices[$0] }
        for index in indicesToRemove.sorted(by: >) {  // Remove from highest to lowest to prevent index shifting
            let filterList = filterLists[index]
            if let customIndex = customFilterLists.firstIndex(of: filterList) {
                customFilterLists.remove(at: customIndex)
            }
            filterLists.remove(at: index)
        }
        saveCustomFilterLists()
    }

    private func checkAndCreateBlockerList() {
        guard let containerURL = GroupContainerURL.groupContainerURL() else {
            Logger.logMessage("Error: Unable to access shared container")
            return
        }
        let fileURL = containerURL.appendingPathComponent("blockerList.json")

        if fileManager.fileExists(atPath: fileURL.path) {
            Logger.logMessage(
                "blockerList.json already exists at \(fileURL.path)")
            return
        }

        do {
            // Create an empty JSON array and write to the file
            let emptyArray: [[String: Any]] = []
            let data = try JSONSerialization.data(
                withJSONObject: emptyArray, options: [])
            try data.write(to: fileURL, options: .atomic)
            Logger.logMessage(
                "Created empty blockerList.json at \(fileURL.path)")
        } catch {
            Logger.logMessage(
                "Error creating blockerList.json: \(error.localizedDescription)"
            )
        }
    }

    private func checkAndCreateGroupFolder() {
        guard let containerURL = GroupContainerURL.groupContainerURL() else {
            Logger.logMessage("Error: Unable to access shared container")
            return
        }

        if FileManager.default.fileExists(atPath: containerURL.path) {
            Logger.logMessage(
                "Group folder already exists: \(containerURL.path)")
            return
        }

        do {
            try FileManager.default.createDirectory(
                at: containerURL, withIntermediateDirectories: true)
            Logger.logMessage("Created group folder: \(containerURL.path)")
        } catch {
            Logger.logMessage(
                "Error creating group folder: \(error.localizedDescription)")
        }
    }

    private func loadSelectedState() {
        if checkSelectedStateForAnyFilter() {
            let defaults = UserDefaults.standard
            for index in filterLists.indices {
                filterLists[index].isSelected = defaults.bool(
                    forKey: "filter_\(filterLists[index].name)")
            }
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

    // Get Last Update Date
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

    // Set Selection for Filter List
    func setSelection(for filterList: FilterList, isSelected: Bool) {
        if let index = filterLists.firstIndex(where: { $0.id == filterList.id })
        {
            filterLists[index].isSelected = isSelected
            objectWillChange.send()
        }
    }

    nonisolated func processFilterLists(
        selectedLists: [FilterListData],
        urlSession: URLSession
    ) async -> [(ConversionResult, String)] {
        var results = [(ConversionResult, String)]()
        let processor = FilterListProcessor(urlSession: urlSession)
        await withTaskGroup(of: (ConversionResult, String).self) { group in
            for listData in selectedLists {
                let listURL = listData.urlString
                let listName = listData.name
                group.addTask {
                    do {
                        guard let url = URL(string: listURL) else {
                            throw URLError(.badURL)
                        }
                        let data = try await processor.downloadFilterList(
                            from: url, name: listName)
                        let parsed = try processor.parseRules(data)
                        let converted =
                            try await processor.convertToAdGuardFormat(parsed)
                        return (converted, listData.id)
                    } catch {
                        // Log error on main actor
                        await MainActor.run {
                            Logger.logMessage(
                                "Error processing filter list: \(error)")
                        }
                        return (
                            ConversionResult(
                                entries: [],
                                limit: 0,
                                errorsCount: 0,
                                message: ""
                            ), UUID().uuidString
                        )
                    }
                }
            }

            // Collect results from the task group
            for await result in group {
                results.append(result)
            }
        }
        return results
    }

    @MainActor
    func applyChanges() async {
        let selectedLists = filterLists.filter { $0.isSelected }
        // Convert to FilterListData array to ensure Sendable
        let selectedListData = selectedLists.map { filterList in
            FilterListData(
                name: filterList.name,
                urlString: filterList.url.absoluteString,
                category: filterList.category,
                isSelected: filterList.isSelected,
                description: filterList.desc,
                isAdGuardAnnoyancesList: filterList.isAdGuardAnnoyancesList
            )
        }
        var allRules: [[String: Any]] = []
        totalStats = .init()  // Reset total stats

        progress = 0
        let totalLists = selectedLists.count
        var processedLists = 0

        // Run processFilterLists() in a detached task
        let results = await Task.detached {
            () -> [(ConversionResult, String)] in
            await self.processFilterLists(
                selectedLists: selectedListData, urlSession: self.urlSession)
        }.value

        Logger.logMessage("Number of results received: \(results.count)")

        // Process results on the main actor
        for (converted, listID) in results {
            if let newRules = try? JSONSerialization.jsonObject(
                with: Data(converted.converted.utf8), options: []
            ) as? [[String: Any]] {
                allRules.append(contentsOf: newRules)
            }

            // Save last update date
            if let list = self.filterLists.first(where: { $0.id == listID }) {
                self.saveLastUpdateDate(filter: list)
            }

            self.updateTotalStats(with: converted)
            self.logMessageConversionStatistics(converted)

            // Update progress
            processedLists += 1
            self.progress = Double(processedLists) / Double(totalLists)
        }

        Logger.logMessage("Total rules collected: \(allRules.count)")

        do {
            try await writeAllRulesToFile(allRules)
            await reloadContentBlocker()
            logMessageTotalConversionStatistics()
        } catch {
            Logger.logMessage("Error writing rules to file: \(error)")
        }

        // Save selected state
        for list in filterLists {
            saveSelectedState(filter: list)
        }
        // Reset progress
        progress = 1.0
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[
            0]
    }

    func saveFilterLists() {
        do {
            let data = try JSONEncoder().encode(filterLists)
            let url = getDocumentsDirectory().appendingPathComponent(
                "filterLists.json")
            try data.write(to: url)
        } catch {
            print("Error saving filter lists: \(error)")
        }
    }

    func loadFilterLists() {
        let url = getDocumentsDirectory().appendingPathComponent(
            "filterLists.json")
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                let data = try Data(contentsOf: url)
                filterLists = try JSONDecoder().decode(
                    [FilterList].self, from: data)
            } catch {
                print("Error loading filter lists: \(error)")
                loadDefaultFilterLists()
            }
        } else {
            loadDefaultFilterLists()
        }
    }

    private func updateTotalStats(with result: ConversionResult) {
        totalStats.totalConvertedCount += result.totalConvertedCount
        totalStats.convertedCount += result.convertedCount
        totalStats.errorsCount += result.errorsCount
        totalStats.overLimit += result.overLimit ? 1 : 0
    }

    private func writeAllRulesToFile(_ rules: [[String: Any]]) async throws {
        guard
            let containerURL = GroupContainerURL.groupContainerURL()
        else {
            throw FilterListError.containerNotFound
        }

        let fileURL = containerURL.appending(path: "blockerList.json")
        Logger
            .logMessage(
                "Writing to blockerList.json at \(fileURL.absoluteString)"
            )
        let data = try JSONSerialization.data(
            withJSONObject: rules, options: .prettyPrinted)
        try data.write(to: fileURL, options: .atomic)

        let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
        if let fileSize = attributes[.size] as? Int64, fileSize > 2_000_000 {
            Logger.logMessage(
                "WARNING: blockerList.json size (\(fileSize) bytes) exceeds 2MB limit for Safari content blockers!"
            )
        }
    }

    // Modify loadFilterLists to ensure shared instances
    private func loadDefaultFilterLists() {
        var filterListDict = [String: FilterList]()

        // First, create all FilterList instances without setting children
        for data in FilterListProvider.filterListData {
            let filterList = FilterList(
                name: data.name,
                url: URL(string: data.urlString)!,
                category: data.category,
                isSelected: data.isSelected,
                description: data.description,
                isAdGuardAnnoyancesList: data.isAdGuardAnnoyancesList
            )
            filterLists.append(filterList)
            filterListDict[data.name] = filterList
        }

        // Now, set up the hierarchy by assigning children
        for data in FilterListProvider.filterListData {
            if let childrenNames = data.childrenNames,
                let parentFilterList = filterListDict[data.name]
            {
                parentFilterList.children = childrenNames.compactMap {
                    childName in
                    if let child = filterListDict[childName] {
                        child.isChild = true  // Mark as child
                        return child
                    }
                    return nil
                }
            }
        }

        // Observe changes in isSelected
        for filterList in filterLists {
            filterList.objectWillChange
                .sink { [weak self] _ in
                    self?.checkForUnsavedChanges()
                    self?.objectWillChange.send()
                }
                .store(in: &cancellables)
        }

        // Load custom filter lists
        loadCustomFilterLists()
    }

    private func checkForUnsavedChanges() {
        for filterList in filterLists {
            if initialSelectedStates[UUID(uuidString: filterList.id)!]
                != filterList.isSelected
            {
                hasUnsavedChanges = true
                return
            }
        }
        hasUnsavedChanges = false
    }

    // Add a Set to hold AnyCancellable references
    //    private var cancellables = Set<AnyCancellable>()

    private func logMessageTotalConversionStatistics() {
        Logger.logMessage(
            """
            Total conversion statistics:
            - Total converted count: \(totalStats.totalConvertedCount)
            - Converted count: \(totalStats.convertedCount)
            - Errors count: \(totalStats.errorsCount)
            - Lists over limit: \(totalStats.overLimit)
            """)
    }

    private func logMessageConversionStatistics(_ result: ConversionResult) {
        Logger.logMessage(
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

    func parseMetadata(from content: String) -> (
        title: String?, description: String?, version: String?
    ) {
        var title: String?
        var description: String?
        var version: String?

        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            if line.hasPrefix("! Title:") {
                title = line.replacingOccurrences(of: "! Title:", with: "")
                    .trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("! Description:") {
                description = line.replacingOccurrences(
                    of: "! Description:", with: ""
                ).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("! Version:") {
                version = line.replacingOccurrences(of: "! Version:", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }

            if title != nil && description != nil && version != nil {
                break
            }
        }

        return (title, description, version)
    }

}
