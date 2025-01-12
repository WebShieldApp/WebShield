import ContentBlockerConverter
import Foundation
import SafariServices
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
    @State private var columnVisibility = NavigationSplitViewVisibility.automatic
    @State private var contentBlockerState = ContentBlockerState()

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selectedCategory: $selectedCategory)
        } detail: {
            detailView
        }
    }

    private var detailView: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isUpdating {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(.linear)
                    .tint(.blue)
            }

            FilterListView(category: selectedCategory ?? .all)
                .navigationTitle(selectedCategory?.rawValue ?? "All")
                .toolbar {
                    toolbarContent()
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

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            Button(action: { showingSettings.toggle() }) {
                Label("Settings", systemImage: "gear")
            }
            .help("Settings")

            PulsatingCircleButton()

            Button(action: { refreshFilters() }) {
                Label("Refresh", systemImage: "arrow.2.circlepath")
            }
            .help("Refresh Filters")
            .disabled(isUpdating)

            Button(action: { showingLogs.toggle() }) {
                Label("Logs", systemImage: "doc.text.magnifyingglass")
            }
            .help("View Logs")

            Button(action: { showingImport.toggle() }) {
                Label("Import", systemImage: "plus")
            }
            .help("Import Filters")
        }
    }

    private var enabledFilterCount: Int {
        filterLists.filter { $0.isEnabled }.count
    }

    /// Summation of counts from both blockerList.json and advancedBlocking.json.
    private var totalRuleCount: Int {
        var combinedCount = 0

        // 1. blockerList.json
        if let blockerListURL = GroupContainerURL.groupContainerURL()?
            .appendingPathComponent("blockerList.json")
        {
            combinedCount += jsonArrayCount(at: blockerListURL)
        }

        // 2. advancedBlocking.json
        if let advancedBlockingURL = GroupContainerURL.groupContainerURL()?
            .appendingPathComponent("advancedBlocking.json")
        {
            combinedCount += jsonArrayCount(at: advancedBlockingURL)
        }

        return combinedCount
    }

    /// Safely decodes a file as a top-level JSON array, then returns its count.
    /// If the file is missing or invalid, returns 0.
    private func jsonArrayCount(at fileURL: URL) -> Int {
        guard
            let data = try? Data(contentsOf: fileURL),
            let jsonObject = try? JSONSerialization.jsonObject(with: data),
            let array = jsonObject as? [Any]
        else {
            return 0
        }
        return array.count
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

    func refreshFilters() {
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
            guard let enabledLists = try? modelContext.fetch(fetchDescriptor) else {
                LogsView.logProcessingStep("Failed to fetch enabled filter lists", for: "System")
                return
            }

            totalLists = enabledLists.count

            // --- NEW: If totalLists is 0, skip the loop & just finalize. ---
            if totalLists == 0 {
                LogsView.logProcessingStep("No filters are enabled; writing empty blocklist.", for: "Refresh")

                // Write empty files
                do {
                    if let groupURL = GroupContainerURL.groupContainerURL() {
                        // Save empty .json
                        try await filterListProcessor.saveContentBlockerFiles(results: [], directoryURL: groupURL)
                    }
                    // Reload content blocker anyway
                    await contentBlockerState.reloadContentBlocker()
                } catch {
                    LogsView.addLog("Failed to handle empty filters: \(error)")
                }

                return  // short‐circuit
            }

            // Otherwise, proceed as usual
            var allResults: [ProcessedConversionResult] = []

            for (index, list) in enabledLists.enumerated() {
                do {
                    let result = try await filterListProcessor.processFilterList(list)
                    allResults.append(result)
                    // UI progress
                    currentList = index + 1
                    progress = Double(currentList) / Double(totalLists)

                } catch {
                    LogsView.logProcessingStep(
                        "Failed to process \(list.name): \(error.localizedDescription)", for: list.name)
                }
            }

            do {
                if let groupURL = GroupContainerURL.groupContainerURL() {
                    try await filterListProcessor.saveContentBlockerFiles(results: allResults, directoryURL: groupURL)
                } else {
                    LogsView.logProcessingStep("Could not find App Group container URL.", for: "System")
                }

                LogsView.addLog("Saving Model")
                try modelContext.save()
                LogsView.addLog("Reloading Content Blocker")
                await contentBlockerState.reloadContentBlocker()

            } catch {
                LogsView.addLog("Failed to save content blocker files: \(error)")
            }
        }
    }
}

#Preview {
    @Previewable var dataManager = DataManager()
    ContentView()
        .modelContainer(dataManager.container)
        .environmentObject(dataManager)
        .onAppear {
            dataManager.seedDataIfNeeded()
        }
}
