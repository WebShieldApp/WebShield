import SwiftUI

struct FilterListView: View {
    let category: FilterListCategory
    @EnvironmentObject private var filterListManager: FilterListManager
    @StateObject private var viewModel: FilterListViewModel
    @State private var showingLogs = false
    @State private var showingImport = false
    @State private var isUpdating = false

    init(
        category: FilterListCategory
    ) {
        self.category = category
        self._viewModel = StateObject(
            wrappedValue: FilterListViewModel(category: category))
    }

    var body: some View {
        Form {
            if category == .all {
                ForEach(FilterListCategory.allCases.dropFirst(), id: \.self) {
                    category in
                    Section(header: Text(category.rawValue)) {
                        ForEach(groupedFilterLists(for: category)) {
                            filterList in
                            FilterListToggle(filterList: filterList)
                        }
                    }
                }
            } else {
                Section {
                    ForEach(filterListsForCategory) { filterList in
                        FilterListToggle(filterList: filterList)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(category.rawValue)
        .toolbar {
            //            ActionButtons(
            //                applyChanges: filterListManager.applyChanges,
            //                logsText: filterListManager.logs,
            //                showingLogs: $showingLogs,
            //                showingImport: $showingImport
            //            )
            ToolbarItem(placement: .automatic) {
                Button("Show Logs") {
                    showingLogs = true
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Refresh All") {
                    Task {
                        isUpdating = true
                        await filterListManager.applyChanges()
                        isUpdating = false
                    }
                }
                .disabled(isUpdating)
            }
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    // button activates link
                    showingImport.toggle()
                }) {
                    Image(systemName: "plus")
                        .resizable()
                        .padding(6)
                        .frame(width: 24, height: 24)
                    //                    .foregroundColor(.white)
                }
            }

        }
        .sheet(isPresented: $showingLogs) {
            LogsView(logs: Logger.logs)
        }
        .sheet(isPresented: $showingImport) {
            ImportView()
        }
    }

    private var filterListsForCategory: [FilterList] {
        filterListManager.filterLists.filter { $0.category == category }
    }

    private func groupedFilterLists(for category: FilterListCategory)
        -> [FilterList]
    {
        filterListManager.filterLists.filter { $0.category == category }
    }
}
