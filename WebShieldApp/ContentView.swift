@preconcurrency import ContentBlockerConverter
import Foundation
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FilterList.order, order: .forward) private var filterLists: [FilterList]
    @State private var selectedCategory: FilterListCategory? = .all
    @State private var isUpdating = false
    @State private var showingLogs = false
    @State private var showingImport = false
    @State private var showingSettings = false
    @State private var progress: Double = 0
    @State private var currentList: Int = 0
    private let filterListProcessor = FilterListProcessor()
    @State private var totalLists: Int = 0
    @State private var columnVisibility = NavigationSplitViewVisibility
        .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selectedCategory: $selectedCategory)
                .navigationSplitViewColumnWidth(140)
                .navigationSplitViewStyle(.balanced)
        } detail: {
            VStack(spacing: 0) {
                if isUpdating {
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(.linear)
                        .tint(.blue)
                }

                FilterListView(category: selectedCategory ?? .all)
                    .navigationTitle(selectedCategory?.rawValue ?? "All")
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarLeading) {
                            Button(action: { showingSettings.toggle() }) {
                                Label(
                                    "Settings",
                                    systemImage: "gear")
                            }
                            .help("Settings")
                        }

                        ToolbarItemGroup(placement: .automatic) {
                            HStack {
                                PulsatingCircleButton()
                                Button(action: { refreshFilters() }) {
                                    Label("Refresh", systemImage: "arrow.2.circlepath")
                                }
                                .help("Refresh Filters")
                                .disabled(isUpdating)

                                Button(action: { showingLogs.toggle() }) {
                                    Label(
                                        "Logs",
                                        systemImage: "doc.text.magnifyingglass")
                                }
                                .help("View Logs")

                                Button(action: { showingImport.toggle() }) {
                                    Label("Import", systemImage: "plus")
                                }
                                .help("Import Filters")
                            }
                        }
                    }
                    .sheet(isPresented: $showingLogs) {
                        LogsView()
                    }
                    .sheet(isPresented: $showingImport) {
                        ImportView()
                    }
                    .sheet(isPresented: $showingSettings) {
                        SettingsView()
                    }
            }
        }

    }

    private var enabledFilterCount: Int {
        filterLists.filter { $0.isEnabled }.count
    }

    private var totalRuleCount: Int {
            // Read both blockerList.json and advancedBlocking.json to get the combined rule count

        var combinedRuleCount = 0

            // Read blockerList.json (regular rules)
        if let blockerListURL = GroupContainerURL.groupContainerURL()?
            .appendingPathComponent("blockerList.json"),
           let blockerListData = try? Data(contentsOf: blockerListURL)
        {
        if let rules = try? JSONDecoder().decode(
            [Rule].self, from: blockerListData)
        {
        combinedRuleCount += rules.count
        }
        }

            // Read advancedBlocking.json (advanced rules)
        if let advancedBlockingURL = GroupContainerURL.groupContainerURL()?
            .appendingPathComponent("advancedBlocking.json"),
           let advancedBlockingData = try? Data(
            contentsOf: advancedBlockingURL)
        {
        if let rules = try? JSONDecoder().decode(
            [ContentBlockerRule].self, from: advancedBlockingData
        ) {
            combinedRuleCount += rules.count
        }
        }

        return combinedRuleCount
    }

    private func shouldShowSection(_ category: FilterListCategory) -> Bool {
        selectedCategory == .all || category == selectedCategory
    }

    private var groupedFilterLists: [FilterListSection] {
        let categoryOrder: [FilterListCategory] = [
            .ads, .privacy, .security, .multipurpose,
            .social, .cookies, .annoyances, .regional,
            .experimental, .custom,
        ]

        let sortedLists = filterLists.sorted { $0.order < $1.order }
        var sections: [FilterListCategory: [FilterList]] = [:]

        for list in sortedLists {
            if let category = list.category {
                sections[category, default: []].append(list)
            }
        }

        return categoryOrder.compactMap { category in
            if let lists = sections[category], !lists.isEmpty {
                return FilterListSection(
                    title: category.rawValue,
                    filterLists: lists,
                    category: category
                )
            }
            return nil
        }
    }

    private func refreshFilters() {
        Task {
            isUpdating = true
            progress = 0
            currentList = 0

            defer {
                isUpdating = false
                progress = 0
                currentList = 0
                totalLists = 0
            }

            LogsView.logRefreshStart()

            let fetchDescriptor = FetchDescriptor<FilterList>(
                predicate: #Predicate { $0.isEnabled == true }
            )

            guard let enabledLists = try? modelContext.fetch(fetchDescriptor)
            else {
                LogsView.logProcessingStep(
                    "Failed to fetch enabled filter lists", for: "System")
                return
            }

            totalLists = enabledLists.count
            var allConversionResults: [ProcessedConversionResult] = []

            for (index, enabledList) in enabledLists.enumerated() {
                do {
                    let (conversionResult, version, homepage):
                    (ProcessedConversionResult, String, String?)

                    if let providerData = FilterListProvider.filterListData
                        .first(where: {
                            $0.name == enabledList.name
                        })
                    {
                    (conversionResult, version, homepage) =
                    try await filterListProcessor.downloadAndParse(
                        from: URL(string: providerData.urlString)!,
                        id: enabledList.id,
                        name: enabledList.name,
                        existingHomepage: enabledList.homepageURL
                    )
                    } else if let urlString = enabledList.urlString,
                              let url = URL(string: urlString)
                    {
                    (conversionResult, version, homepage) =
                    try await filterListProcessor.downloadAndParse(
                        from: url,
                        id: enabledList.id,
                        name: enabledList.name,
                        existingHomepage: enabledList.homepageURL
                    )
                    } else {
                        LogsView.logProcessingStep(
                            "No URL found for filter list",
                            for: enabledList.name)
                        continue
                    }

                    enabledList.version = version
                    if enabledList.homepageURL == nil
                        || enabledList.homepageURL?.isEmpty == true
                    {
                    enabledList.homepageURL = homepage
                    }
                    allConversionResults.append(conversionResult)

                    filterListProcessor.hasDownloaded(filterList: enabledList)

                        // Update rule counts in SwiftData
                    filterListProcessor.updateFilterListRuleCounts(
                        filterList: enabledList,
                        result: conversionResult
                    )

                    await MainActor.run {
                        currentList = index + 1
                        progress = Double(currentList) / Double(totalLists)
                    }

                } catch {
                    LogsView.logProcessingStep(
                        "Failed to process: \(error.localizedDescription)",
                        for: enabledList.name
                    )
                }
            }

                // Save conversion results
            do {
                let blockerListURL = GroupContainerURL.groupContainerURL()?
                    .appendingPathComponent("blockerList.json")

                if let url = blockerListURL {
                    try await filterListProcessor.saveContentBlockerRules(
                        to: url,
                        conversionResults: allConversionResults
                    )
                }

                    // Save the changes to SwiftData
                try modelContext.save()

            } catch {
                print("Failed to save conversion results: \(error)")
            }
        }
    }
}
