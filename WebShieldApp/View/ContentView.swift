@preconcurrency import ContentBlockerConverter
import Foundation
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FilterList.order, order: .forward) private var filterLists:
        [FilterList]
    @State private var selectedCategory: FilterListCategory = .all
    @State private var isUpdating = false
    @State private var showingLogs = false
    @State private var showingImport = false
    @State private var progress: Double = 0
    @State private var currentList: Int = 0
    @State private var totalLists: Int = 0
    private let filterListProcessor = FilterListProcessor()

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedCategory) {
                Section {
                    let categories: [FilterListCategory] = [
                        .all, .regional, .custom,
                    ]
                    ForEach(categories, id: \.self) { category in
                        NavigationLink(value: category) {
                            Label(
                                category.rawValue,
                                systemImage: category.systemImage
                            )
                        }
                    }
                } header: {
                    Text("Categories")
                }
            }
            .navigationTitle("WebShield")
        } detail: {
            VStack(spacing: 0) {
                if isUpdating {
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(.linear)
                        .tint(.blue)
                }

                FilterListView(category: selectedCategory)
                    .navigationTitle(selectedCategory.rawValue)
                    .toolbar {
                        ToolbarItemGroup(placement: .automatic) {
                            Button(action: { resetModel() }) {
                                Label("Reset", systemImage: "trash")
                            }
                            .help("Reset Model")

                            Button(action: { refreshFilters() }) {
                                Label("Refresh", systemImage: "arrow.clockwise")
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
                    .sheet(isPresented: $showingLogs) {
                        LogsView()
                    }
                    .sheet(isPresented: $showingImport) {
                        ImportView()
                    }
            }
        }
    }

    private var enabledFilterCount: Int {
        filterLists.filter { $0.isEnabled }.count
    }

    private var totalRuleCount: Int {
        // Read the blockerList.json to get the actual rule count
        if let url = GroupContainerURL.groupContainerURL()?
            .appendingPathComponent("blockerList.json"),
            let data = try? Data(contentsOf: url),
            let rules = try? JSONDecoder().decode([String].self, from: data)
        {
            return rules.count
        }
        return 0
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

    private func resetModel() {
        do {
            try modelContext.delete(model: FilterList.self)
            try modelContext.save()
            seedDataIfNeeded()
        } catch {
            print("Failed to reset model: \(error)")
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
            var allConversionResults: [ConversionResult] = []

            for (index, enabledList) in enabledLists.enumerated() {
                do {
                    let (conversionResult, version, homepage):
                        (ConversionResult, String, String?)

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
                let blockerListURL = GroupContainerURL.groupContainerURL()!
                    .appendingPathComponent("blockerList.json")
                try filterListProcessor.saveContentBlockerRules(
                    to: blockerListURL,
                    conversionResults: allConversionResults
                )

                // Save the changes to SwiftData
                try modelContext.save()

            } catch {
                print("Failed to save conversion results: \(error)")
            }
        }
    }

    private func seedDataIfNeeded() {
        for (index, data) in FilterListProvider.filterListData.enumerated() {
            filterListProcessor.saveFilterList(
                to: modelContext,
                id: data.id,
                name: data.name,
                version: "N/A",
                description: data.description,
                category: data.category,
                isEnabled: data.isSelected,
                order: index,
                homepageURL: data.homepageURL
            )
        }
        try? modelContext.save()
    }
}
