import SwiftUI

struct SidebarView: View {
//    @Binding var selectedCategory: FilterListCategory?

    var body: some View {
        List {
            CategoryNav(category: .all)
            CategoryNav(category: .regional)
            CategoryNav(category: .custom)
        }
        .listStyle(SidebarListStyle())
    }
}
