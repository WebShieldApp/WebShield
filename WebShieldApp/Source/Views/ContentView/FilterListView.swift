import SwiftData
import SwiftUI

struct FilterListView: View {
    var category: FilterListCategory
    @Query(sort: \FilterList.order, order: .forward) private var filterLists: [FilterList]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText: String = ""

    var body: some View {
        List {
            let filteredLists = getFilteredLists()

            if !filteredLists.isEmpty {
                StatsView(filteredLists: filteredLists)
            }

            let groupedLists = getGroupedFilterLists(filteredLists: filteredLists)
            ForEach(groupedLists, id: \.id) { section in
                filterListSectionView(section: section)
            }
        }
        .listStyle(.automatic)
        .searchable(text: $searchText)
    }

    // MARK: - Helper Methods

    private func getFilteredLists() -> [FilterList] {
        filterLists.filter { filterList in
            let categoryMatches = (category == .all || filterList.category == category)

            let searchTextLowercased = searchText.lowercased()
            let nameMatches = searchText.isEmpty || filterList.name.lowercased().contains(searchTextLowercased)
            let descMatches = searchText.isEmpty || filterList.desc.lowercased().contains(searchTextLowercased)

            return categoryMatches && (nameMatches || descMatches)
        }
    }

    private func getGroupedFilterLists(filteredLists: [FilterList]) -> [FilterListSection] {
        let sortedLists = filteredLists.sorted { $0.order < $1.order }
        var sections: [FilterListCategory: [FilterList]] = [:]

        for list in sortedLists {
            if let category = list.category {
                sections[category, default: []].append(list)
            }
        }

        let categoryOrder: [FilterListCategory] = [
            .ads, .privacy, .security, .multipurpose, .social,
            .cookies, .annoyances, .regional, .experimental,
        ]

        var orderedSections = categoryOrder.compactMap { category in
            if let lists = sections[category], !lists.isEmpty {
                return FilterListSection(title: category.rawValue, filterLists: lists, category: category)
            }
            return nil
        }

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

    @ViewBuilder
    private func filterListSectionView(section: FilterListSection) -> some View {
        Section(header: Text(section.title).font(.headline).textCase(.none)) {
            ForEach(section.filterLists) { filterList in
                filterListRowView(filterList: filterList)
            }
        }
    }

    @ViewBuilder
    private func filterListRowView(filterList: FilterList) -> some View {
        FilterListRow(filterList: filterList)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                if filterList.category == .custom {
                    Button(role: .destructive) {
                        withAnimation {
                            _ = Task<Void, Never> {
                                await deleteFilterList(filterList)
                            }
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .padding()
    }

    @MainActor
    private func deleteFilterList(_ filterList: FilterList) async {
        modelContext.delete(filterList)
        do {
            try modelContext.save()
        } catch {
            await WebShieldLogger.shared.log("Failed to delete filter list: \(error)")
        }
    }
}
