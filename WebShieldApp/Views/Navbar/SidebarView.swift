import SwiftUI

struct SidebarView: View {
    @Binding var selectedCategory: FilterListCategory?

    var body: some View {
        List(selection: $selectedCategory) {
            Section {
                ForEach(FilterListCategory.allCases, id: \.self) { category in
                    NavigationLink(
                        destination: FilterListView(category: category)
                    ) {
                        CategoryNav(category: category)
                    }
                }
            } header: {
                Text("Categories")
            }
        }
        .listStyle(SidebarListStyle())
    }
}
