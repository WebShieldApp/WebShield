import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var filterListManager: FilterListManager
    @State private var isUpdating = false
    @State private var progress: Float = 0
    @State private var showMissingFiltersAlert = false
    @State private var selectedFilter: FilterList?
    @State private var showDescription = false
    @State private var selectedCategory: FilterListCategory? = .all

    private var groupedFilterLists: [FilterListCategory: [FilterList]] {
        Dictionary(grouping: filterListManager.filterLists, by: { $0.category })
    }

    public var body: some View {
        NavigationSplitView(
            sidebar: {
                List {
                    ForEach(FilterListCategory.allCases, id: \.self) {
                        category in
                        CategoryNav(
                            category: category
                        )
                    }
                }
                .listStyle(SidebarListStyle())
            },
            detail: {
                // Right Column: Filter Lists
                if let selectedCategory = selectedCategory {
                    FilterListView(category: selectedCategory)
                } else {
                    Text("Select a category")
                        .navigationTitle("Filter Lists")
                }
            }
        )
    }

    func updateFilters() {
        isUpdating = true
        progress = 0

        // Add your updateFilters logic here
    }
}

struct CategoryNav: View {
    let category: FilterListCategory

    var body: some View {
        NavigationLink(destination: FilterListView(category: category)) {
            Label("\(category.rawValue)", systemImage: "circle.fill")
        }
    }
}

struct FilterListView: View {
    let category: FilterListCategory
    @EnvironmentObject var filterListManager: FilterListManager

    var body: some View {
        List {
            if category == .all {
                ForEach(filterListManager.filterLists) {
                    filterList in
                    Toggle(
                        filterList.name,
                        isOn: Binding(
                            get: { filterList.isSelected },
                            set: { _, _ in
                                filterListManager.toggleFilterListSelection(
                                    id: filterList.id)
                            }
                        )
                    ).toggleStyle(DefaultToggleStyle())
                }
            } else {
                ForEach(
                    filterListManager.filterLists.filter {
                        $0.category == category
                    }
                ) { filterList in
                    Toggle(
                        filterList.name,
                        isOn: Binding(
                            get: { filterList.isSelected },
                            set: { _, _ in
                                filterListManager.toggleFilterListSelection(
                                    id: filterList.id)
                            }
                        )
                    ).toggleStyle(DefaultToggleStyle())
                }
            }
        }
        .navigationTitle(category.rawValue)
        #if os(iOS)
            .listStyle(InsetGroupedListStyle())
        #else
            .listStyle(DefaultListStyle())
        #endif
        ActionButtons(
//                        isUpdating: $isUpdating,
//                        progress: $progress,
//                        updateFilters: updateFilters,
            applyChanges: filterListManager.applyChanges
        )
    }
}

struct ActionButtons: View {
//    @Binding var isUpdating: Bool
//    @Binding var progress: Float
//    let updateFilters: () -> Void
    let applyChanges: @MainActor @Sendable () async -> Void

    var body: some View {
        HStack {
//            Button("Update Filters", action: updateFilters)
////                .disabled(
////                    isUpdating
////                )
//                .padding()
            Button("Download & Apply Filters", action: { Task { await applyChanges() } })
                .padding()
        }
    }
}
