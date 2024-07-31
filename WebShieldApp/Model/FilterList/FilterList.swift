import Foundation

struct FilterList: Identifiable, Equatable {
    let id: UUID
    let name: String
    let url: URL
    let category: FilterListCategory
    var isSelected: Bool
    let desc: String
    let isAdGuardAnnoyancesList: Bool

    init(
        name: String, url: URL, category: FilterListCategory,
        isSelected: Bool = false,
        description: String = "Lorem ipsum description.",
        isAdGuardAnnoyancesList: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.url = url
        self.category = category
        self.isSelected = isSelected
        self.desc = description
        self.isAdGuardAnnoyancesList = isAdGuardAnnoyancesList
    }
}
