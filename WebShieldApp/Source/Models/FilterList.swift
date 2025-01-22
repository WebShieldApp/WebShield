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
    var downloadUrl: String? = "https://example.com"
    var homepageUrl: String? = "https://example.com"
    var standardRuleCount: Int = 0
    var advancedRuleCount: Int = 0
    var lastUpdated: Date = Date()
    var informationUrl: String? = "https://example.com"
    var downloaded: Bool = false
    var needsRefresh: Bool = true

    // Initializer
    init(
        name: String = "No Name",
        version: String = "No Version",
        desc: String = "No Description",
        category: FilterListCategory,
        isEnabled: Bool = false,
        order: Int = 0,
        downloadUrl: String? = nil,
        homepageUrl: String? = nil,
        informationUrl: String? = nil,
        downloaded: Bool = false,
        needsRefresh: Bool = true
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.version = version
        self.desc = desc
        self.categoryString = category.rawValue
        self.isEnabled = isEnabled
        self.order = order
        self.downloadUrl = downloadUrl
        self.homepageUrl = homepageUrl
        self.informationUrl = informationUrl
        self.downloaded = false
        self.needsRefresh = true
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
