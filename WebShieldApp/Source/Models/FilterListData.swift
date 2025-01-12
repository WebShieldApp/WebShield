import Foundation

struct FilterListData {
    let id: String
    let name: String
    let urlString: String
    let category: FilterListCategory
    let isSelected: Bool
    let description: String
    let homepageURL: String?
    let informationURL: String?

    init(
        id: String,
        name: String,
        urlString: String,
        category: FilterListCategory,
        isSelected: Bool,
        description: String,
        homepageURL: String? = nil,
        informationURL: String? = nil
    ) {
        self.id = id
        self.name = name
        self.urlString = urlString
        self.category = category
        self.isSelected = isSelected
        self.description = description
        self.homepageURL = homepageURL
        self.informationURL = informationURL
    }
}
