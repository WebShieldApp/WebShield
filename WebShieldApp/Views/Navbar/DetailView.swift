import SwiftUI

struct DetailView: View {

    let selectedCategory: FilterListCategory?

    var body: some View {
        Group {
            if let category = selectedCategory {
                FilterListView(category: category)
            } else {
                Text("Select a category")
            }
        }
    }
}
