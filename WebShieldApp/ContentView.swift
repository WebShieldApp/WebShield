import SwiftUI

struct ContentView: View {
    @StateObject private var filterListManager = FilterListManager()
    @State private var isFetching = false
    @State private var progress: CGFloat = 0.0

    private var groupedFilterLists: [FilterListCategory: [FilterList]] {
        Dictionary(grouping: filterListManager.filterLists, by: { $0.category })
    }
    @State private var expandedGroups: Set<FilterListCategory> = Set(FilterListCategory.allCases)

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(FilterListCategory.allCases, id: \.self) { category in
                        if let filterLists = groupedFilterLists[category] {
                            CategoryDisclosureGroup(
                                category: category,
                                filterLists: filterLists,
                                filterListManager: filterListManager,
                                isExpanded: .constant(true)
                            )
                        }
                    }
                }
                .listStyle(InsetListStyle())
                HStack {
                    Checkbox(isOn: .constant(false))
                    Text("Advanced Blocking")
                }
                if isFetching {
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding()
                }
                
                HStack {
                    Button(action: {
                        isFetching = true
                        filterListManager.applyChanges {
                            isFetching = false
                        }
                    }) {
                        Label("Fetch & Apply Changes", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button(action: {
                        isFetching = true
                        filterListManager.refreshAndReloadContentBlocker {
                            isFetching = false
                        }
                    }) {
                        Label("Refresh & Reload", systemImage: "arrow.triangle.2.circlepath.circle.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding()
            }
            .navigationTitle("WebShield")
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.blue)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct CategoryDisclosureGroup: View {
    var category: FilterListCategory
    @State var filterLists: [FilterList]
    @ObservedObject var filterListManager: FilterListManager
    @Binding var isExpanded: Bool

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach($filterLists) { $filterList in
                if let index = filterListManager.filterLists.firstIndex(where: { $0.id == filterList.id }) {
                    FilterListRow(filterList: $filterListManager.filterLists[index])
                        .padding(.leading, 20)
                }
            }
        } label: {
            HStack {
                Checkbox(isOn: .constant(filterLists.contains(where: { $0.isSelected })))
                Text(category.rawValue.capitalized)
                    .font(.headline)
                Spacer()
                Text("\(filterLists.filter { $0.isSelected }.count)/\(filterLists.count)")
                    .foregroundColor(.gray)
            }
        }
    }
}

struct FilterListRow: View {
    @Binding var filterList: FilterList

    var body: some View {
        HStack {
            Checkbox(isOn: $filterList.isSelected)
            Text(filterList.name)
                .font(.body)
            Spacer()
            if filterList.isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
    }
}

struct Checkbox: View {
    @Binding var isOn: Bool

    var body: some View {
        Button(action: {
            isOn.toggle()
        }) {
            Image(systemName: isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(isOn ? .blue : .gray)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

