import SwiftData
import SwiftUI

struct FilterListView: View {
    var category: FilterListCategory
    @Query(sort: \FilterList.order, order: .forward) private var filterLists: [FilterList]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText: String = ""

    var body: some View {
        List {
            if !filteredLists.isEmpty {
                StatsView(filteredLists: filteredLists)
            }

            ForEach(groupedFilterLists, id: \.id) { section in
                Section {
                    ForEach(section.filterLists) { filterList in
                        FilterListRow(filterList: filterList)
                            .swipeActions(
                                edge: .trailing, allowsFullSwipe: true
                            ) {
                                if filterList.category == .custom {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            deleteFilterList(filterList)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                            .padding()

                    }
                } header: {
                    Text(section.title)
                        .font(.headline)
                        .textCase(.none)
                        .foregroundStyle(.primary)
                }
            }
        }
        .listStyle(.automatic)
        .searchable(text: $searchText)
    }

    private var filteredLists: [FilterList] {
        filterLists.filter { filterList in
            // Match category if it's not `.all`
            let categoryMatches =
                (category == .all || filterList.category == category)

            // Match name if user typed something in search bar
            let nameMatches =
                searchText.isEmpty
                || filterList.name.localizedCaseInsensitiveContains(searchText)

            return categoryMatches && nameMatches
        }
    }

    private var groupedFilterLists: [FilterListSection] {
        let sortedLists = filteredLists.sorted { $0.order < $1.order }
        var sections: [FilterListCategory: [FilterList]] = [:]

        for list in sortedLists {
            if let category = list.category {
                sections[category, default: []].append(list)
            }
        }

        // Define category order with custom at the end
        let categoryOrder: [FilterListCategory] = [
            .ads, .privacy, .security, .multipurpose,
            .social, .cookies, .annoyances, .regional,
            .experimental,
        ]

        var orderedSections = categoryOrder.compactMap { category in
            if let lists = sections[category], !lists.isEmpty {
                return FilterListSection(
                    title: category.rawValue,
                    filterLists: lists,
                    category: category
                )
            }
            return nil
        }

        // Add custom section at the end if it exists
        if let customLists = sections[.custom], !customLists.isEmpty {
            orderedSections.append(
                FilterListSection(
                    title: FilterListCategory.custom.rawValue,
                    filterLists: customLists,
                    category: .custom
                )
            )
        }

        return orderedSections
    }

    private func deleteFilterList(_ filterList: FilterList) {
        modelContext.delete(filterList)
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete filter list: \(error)")
        }
    }
}
