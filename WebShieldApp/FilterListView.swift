import SwiftData
import SwiftUI

struct FilterListView: View {
    var category: FilterListCategory
    @Query(sort: \FilterList.order, order: .forward) private var filterLists: [FilterList]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText: String = ""

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

    private var enabledCount: Int {
        filteredLists.filter { $0.isEnabled }.count
    }

    private var totalRules: Int {
        filteredLists.filter { $0.isEnabled }.reduce(0) {
            $0 + $1.totalRuleCount
        }
    }

    var body: some View {
        List {
            if !filteredLists.isEmpty {
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.blue.opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: "shield")
                                .imageScale(.medium)
                                .foregroundStyle(.blue)
                                .fontWeight(.semibold)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline, spacing: 0) {
                                Text("\(enabledCount)")
                                    .font(.title2)
                                    .bold()
                                    .frame(width: 45, alignment: .leading)
                                    .padding(.horizontal)
                                    //                                Text("•")
                                    //                                    .font(.title2)
                                    //                                    .foregroundStyle(.secondary)
                                    //                                    .frame(width: 32, alignment: .center)
                                Text("\(totalRules)")
                                    .font(.title2)
                                    .bold()
                                    .frame(alignment: .leading)
                            }

                            HStack(alignment: .firstTextBaseline, spacing: 0) {
                                Text("Enabled")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 45, alignment: .leading)
                                    .padding(.horizontal)
                                    //                                Text("•")
                                    //                                    .font(.subheadline)
                                    //                                    .foregroundStyle(.secondary)
                                    //                                    .frame(width: 32, alignment: .center)
                                Text("Rules")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(alignment: .leading)
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
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
