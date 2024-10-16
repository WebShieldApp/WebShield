//
//  FilterListView.swift
//  WebShieldApp
//

import SwiftUI

struct FilterListView: View {
    let category: FilterListCategory
    @EnvironmentObject private var filterListManager: FilterListManager
    @State private var showingLogs = false
    @State private var showingImport = false
    @State private var isUpdating = false
    @Environment(\.editMode) private var editMode

    // State variable for animation
    @State private var pulsate = false

    var body: some View {
        VStack {
            if isUpdating {
                ProgressView(value: filterListManager.progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
            }

            List {
                if category == .all {
                    ForEach(FilterListCategory.allCases.dropFirst(), id: \.self)
                    { category in
                        Section(header: Text(category.rawValue)) {
                            ForEach(filterListsForCategory(category)) {
                                filterList in
                                FilterListToggle(filterList: filterList) {
                                    filterListManager.removeCustomFilterList(
                                        filterList)
                                }
                            }
                        }
                    }
                } else {
                    Section(header: Text(category.rawValue)) {
                        ForEach(filterListsForCategory(category)) {
                            filterList in
                            FilterListToggle(filterList: filterList) {
                                filterListManager.removeCustomFilterList(
                                    filterList)
                            }
                        }
                        .onDelete(perform: deleteCustomFilterLists)
                        .onMove(perform: moveCustomFilterLists)
                    }
                }
            }
            .listStyle(.automatic)
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: {
                    showingLogs = true
                }) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .imageScale(.large)
                }
                .help("Show Logs")

                Button(action: {
                    Task {
                        isUpdating = true
                        await filterListManager.applyChanges()
                        isUpdating = false
                    }
                }) {
                    Image(
                        systemName: filterListManager.hasUnsavedChanges
                            ? "arrow.clockwise.circle.fill" : "arrow.clockwise"
                    )
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(
                        filterListManager.hasUnsavedChanges ? .white : .primary
                    )
                    .background(
                        filterListManager.hasUnsavedChanges
                            ? Color.blue : Color.clear
                    )
                    .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isUpdating)
                .animation(
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: filterListManager.hasUnsavedChanges
                )
                .help("Refresh All Filters")
                Button(action: {
                    showingImport.toggle()
                }) {
                    Image(systemName: "plus")
                        .imageScale(.large)
                }
                .help("Import Filters")
            }
        }
        .sheet(isPresented: $showingLogs) {
            LogsView(logs: Logger.logs)
        }
        .sheet(isPresented: $showingImport) {
            ImportView()
                .environmentObject(filterListManager)
        }
    }
    private func deleteCustomFilterLists(at offsets: IndexSet) {
        filterListManager.removeCustomFilterList(at: offsets, in: category)
    }

    private func moveCustomFilterLists(
        from source: IndexSet, to destination: Int
    ) {
        filterListManager.moveCustomFilterList(
            fromOffsets: source, toOffset: destination)
    }

    private func filterListsForCategory(_ category: FilterListCategory)
        -> [FilterList]
    {
        filterListManager.filterLists.filter {
            $0.category == category && !$0.isChild
        }
    }
}
