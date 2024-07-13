import Foundation

enum FilterListCategory: String, CaseIterable {
    case ads, privacy, security, multipurpose, annoyances, other, experimental
}

struct FilterList: Identifiable {
    let id: UUID
    let name: String
    let url: URL
    let category: FilterListCategory
    var isSelected: Bool

    init(name: String, url: URL, category: FilterListCategory, isSelected: Bool = false) {
        self.id = UUID()
        self.name = name
        self.url = url
        self.category = category
        self.isSelected = isSelected
    }
}
