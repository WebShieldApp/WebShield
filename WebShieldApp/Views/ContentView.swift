import SwiftUI

struct ContentView: View {
    @State private var selectedCategory: FilterListCategory? = .all
    @StateObject private var filterListManager = FilterListManager()

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            NavigationStack {
                if let category = selectedCategory {
                    FilterListView(
                        category: category
                    ).environmentObject(filterListManager)
                } else {
                    Text("Select a category")
                }
            }
        }
        .environmentObject(filterListManager)
    }
}
