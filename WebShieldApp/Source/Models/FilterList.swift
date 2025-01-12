import Foundation
import SwiftData

// MARK: - Model
@Model
final class FilterList: Identifiable, Hashable {
    @Attribute(.unique) var id: String
    var name: String = "No Name"
    var version: String = "N/A"
    var desc: String = "No Description"
    var categoryString: String = FilterListCategory.custom.rawValue
    var isEnabled: Bool = false
    var order: Int = 0
    var urlString: String? = "https://example.com"
    var homepageURL: String? = "https://example.com"
    var standardRuleCount: Int = 0
    var advancedRuleCount: Int = 0
    var lastUpdated: Date = Date()
    var informationURL: String? = "https://example.com"
    var downloaded: Bool = false

    // Initializer
    init(
        name: String = "No Name",
        version: String = "No Version",
        desc: String = "No Description",
        category: FilterListCategory,
        isEnabled: Bool = false,
        order: Int = 0,
        urlString: String? = nil,
        homepageURL: String? = nil,
        informationURL: String? = nil,
        downloaded: Bool = false
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.version = version
        self.desc = desc
        self.categoryString = category.rawValue
        self.isEnabled = isEnabled
        self.order = order
        self.urlString = urlString
        self.homepageURL = homepageURL
        self.informationURL = informationURL
        self.downloaded = false
    }

    static func == (lhs: FilterList, rhs: FilterList) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var category: FilterListCategory? {
        FilterListCategory(rawValue: categoryString)
    }

    var totalRuleCount: Int {
        standardRuleCount + advancedRuleCount
    }
}
