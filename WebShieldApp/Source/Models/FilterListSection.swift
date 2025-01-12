import Foundation

struct FilterListSection: Identifiable {
    let title: String
    let filterLists: [FilterList]
    let category: FilterListCategory
    var id: String { title }
}
