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

    init(
        contentBlockerIdentifier: String = "me.arjuna.WebShield.ContentBlocker",
        fileManager: FileManager = .default,
        urlSession: URLSession = .shared
    ) {
        self.contentBlockerState = ContentBlockerState(
            withIdentifier: contentBlockerIdentifier)
        self.fileManager = fileManager
        self.urlSession = urlSession

        loadFilterLists()
        filterLists = FilterListProvider.allFilterLists
    }

    func isSelected(_ filterList: FilterList) -> Bool {
        filterLists.first { $0.id == filterList.id }?.isSelected ?? false
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
        let totalSteps = selectedLists.count * 4  // Download, Parse, Convert, Write
        var completedSteps = 0

        for (index, list) in selectedLists.enumerated() {
            do {
                // Download
                let data = try await downloadFilterList(
                    from: list.url, name: list.name)
                completedSteps += 1
                await updateProgress(
                    Double(completedSteps) / Double(totalSteps))

                // Parse
                let parsed = try await parseRules(data)
                completedSteps += 1
                await updateProgress(
                    Double(completedSteps) / Double(totalSteps))

                // Convert
                let converted = try await convertToAdGuardFormat(parsed)
                completedSteps += 1
                await updateProgress(
                    Double(completedSteps) / Double(totalSteps))

                // Write
                let isFirst = index == 0
                let isLast = index == selectedLists.count - 1
                try await writeFilterListToFile(
                    converted, for: list, isFirst: isFirst, isLast: isLast)
                completedSteps += 1
                await updateProgress(
                    Double(completedSteps) / Double(totalSteps))

                printConversionStatistics(converted)
            } catch {
                print("Error processing filter list: \(error)")
            }
        }

        await updateProgress(1.0)  // Ensure progress bar reaches 100%
    }

    private func downloadFilterList(from url: URL, name: String) async throws
        -> Data
    {
        print("Downloading Filter List: \(name) from URL: \(url.absoluteString)")
        let (data, _) = try await self.urlSession.data(from: url)
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
        _ result: ConversionResult, for list: FilterList, isFirst: Bool,
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
            isFirst: isFirst, isLast: isLast)
        if let advanced = result.advancedBlocking {
            try await writeRulesToFile(
                advanced, fileName: "advancedBlocking.json", in: containerURL,
                isFirst: isFirst, isLast: isLast)
        }
    }

    private func writeRulesToFile(
        _ content: String, fileName: String, in containerURL: URL,
        isFirst: Bool, isLast: Bool
    ) async throws {
        let fileURL = containerURL.appendingPathComponent(fileName)
        var existingContent: [[String: Any]] = []

        if fileManager.fileExists(atPath: fileURL.path) {
            let data = try Data(contentsOf: fileURL)
            existingContent =
                try JSONSerialization.jsonObject(with: data, options: [])
                as? [[String: Any]] ?? []
        }

        let newContent =
            try JSONSerialization.jsonObject(
                with: Data(content.utf8), options: []) as? [[String: Any]] ?? []

        if isFirst {
            existingContent = newContent
        } else {
            existingContent.append(contentsOf: newContent)
        }

        if isLast {
            let combinedData = try JSONSerialization.data(
                withJSONObject: existingContent, options: .prettyPrinted)
            try combinedData.write(to: fileURL, options: .atomic)
        }

        let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
        if let fileSize = attributes[.size] as? Int64, fileSize > 2_000_000 {
            print(
                "WARNING: \(fileName) size (\(fileSize) bytes) exceeds 2MB limit for Safari content blockers!"
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

    private func parseRules(_ data: Data) async throws -> [String] {
        print("Parsing rules...")
        guard let content = String(data: data, encoding: .utf8) else {
            throw FilterListError.invalidData
        }

        return content.components(separatedBy: .newlines)
            .filter { !$0.hasPrefix("!") && !$0.hasPrefix("[") && !$0.isEmpty }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
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

    private func refreshAndReloadContentBlocker() async {
        await contentBlockerState.refreshContentBlockerState()
        await contentBlockerState.reloadContentBlocker()
    }
}
