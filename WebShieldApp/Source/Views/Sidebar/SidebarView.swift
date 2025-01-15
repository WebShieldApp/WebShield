import SwiftData
import SwiftUI

struct SidebarView: View {
    @Binding var selectedCategory: FilterListCategory?

    var body: some View {
        List(selection: $selectedCategory) {
            Section(header: Text("Categories")) {
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
            }
        }
        .navigationTitle("WebShield")
    }

}