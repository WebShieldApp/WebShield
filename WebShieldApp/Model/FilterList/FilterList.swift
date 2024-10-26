import Foundation
import SwiftData
import SwiftUI

struct FilterList: Identifiable {
    var id: String
    var name: String
    var url: URL
    //    var category: FilterListCategory
    var isSelected: Bool
    var desc: String
    var version: String
    //    var isAdGuardAnnoyancesList: Bool
    //    var children: [FilterList]?
    //    var isExpanded: Bool
    //    var isChild: Bool

    // Designated initializer
    init(
        id: String = UUID().uuidString,
        name: String = "Unnamed Filter List",
        url: URL,
        //        category: FilterListCategory = .custom,
        isSelected: Bool = false,
        description: String = "Description not available.",
        version: String = "No Version"
            //        isAdGuardAnnoyancesList: Bool = false,
            //        children: [FilterList]? = nil,
            //        isExpanded: Bool = false,
            //        isChild: Bool = false
    ) {
        self.id = id
        self.name = name
        self.url = url
        //        self.category = category
        self.isSelected = isSelected
        self.desc = description
        self.version = version
        //        self.isAdGuardAnnoyancesList = isAdGuardAnnoyancesList
        //        self.children = children
        //        self.isExpanded = isExpanded
        //        self.isChild = isChild
    }

    //    // Make 'init(from decoder:)' a designated initializer
    //    required init(from decoder: Decoder) throws {
    //        let container = try decoder.container(keyedBy: CodingKeys.self)
    //        id = try container.decode(String.self, forKey: .id)
    //        name = try container.decode(String.self, forKey: .name)
    //        url = try container.decode(URL.self, forKey: .url)
    //        category = try container.decode(
    //            FilterListCategory.self, forKey: .category)
    //        isSelected = try container.decode(Bool.self, forKey: .isSelected)
    //        desc = try container.decode(String.self, forKey: .desc)
    //        version = try container.decodeIfPresent(String.self, forKey: .version)
    //        isAdGuardAnnoyancesList = try container.decode(
    //            Bool.self, forKey: .isAdGuardAnnoyancesList)
    //        children = try container.decodeIfPresent(
    //            [FilterList].self, forKey: .children)
    //        isExpanded =
    //            try container.decodeIfPresent(Bool.self, forKey: .isExpanded)
    //            ?? false
    //        isChild =
    //            try container.decodeIfPresent(Bool.self, forKey: .isChild) ?? false
    //    }

    //    // Codable conformance
    //    enum CodingKeys: String, CodingKey {
    //        case id, name, url, category, isSelected, desc, version,
    //            isAdGuardAnnoyancesList, children, isExpanded, isChild
    //    }
    //
    //    func encode(to encoder: Encoder) throws {
    //        var container = encoder.container(keyedBy: CodingKeys.self)
    //        try container.encode(id, forKey: .id)
    //        try container.encode(name, forKey: .name)
    //        try container.encode(url, forKey: .url)
    //        try container.encode(category, forKey: .category)
    //        try container.encode(isSelected, forKey: .isSelected)
    //        try container.encode(desc, forKey: .desc)
    //        try container.encodeIfPresent(version, forKey: .version)
    //        try container.encode(
    //            isAdGuardAnnoyancesList, forKey: .isAdGuardAnnoyancesList)
    //        try container.encodeIfPresent(children, forKey: .children)
    //        try container.encode(isExpanded, forKey: .isExpanded)
    //        try container.encode(isChild, forKey: .isChild)
    //    }

    //    // Additional methods
    //    func updateChildrenSelection(isSelected: Bool) {
    //        children?.forEach { child in
    //            if child.isSelected != isSelected {
    //                child.isSelected = isSelected
    //                child.updateChildrenSelection(isSelected: isSelected)
    //            }
    //        }
    //    }
    //
    //    func updateSelectionBasedOnChildren() {
    //        guard let children = children else { return }
    //        let allSelected = children.allSatisfy { $0.isSelected }
    //        let noneSelected = children.allSatisfy { !$0.isSelected }
    //
    //        if allSelected {
    //            if !isSelected {
    //                isSelected = true
    //            }
    //        } else if noneSelected {
    //            if isSelected {
    //                isSelected = false
    //            }
    //        } else {
    //            // Partially selected (if you want to handle this case)
    //            if isSelected {
    //                isSelected = false
    //            }
    //        }
    //    }
}

struct GenericFilterList {
    let filterList: FilterList
    let filterListCategory: FilterListCategory

    init(
        filterList: FilterList, filterListCategory: FilterListCategory
    ) {
        self.filterList = filterList
        self.filterListCategory = .custom
    }

}

struct ParentFilterList {
    let genericFilterList: GenericFilterList
    var isAdGuardAnnoyancesList: Bool
    var children: [ChildFilterList]
    var isExpanded: Bool

    init(genericFilterList: GenericFilterList, children: [ChildFilterList]) {
        self.genericFilterList = genericFilterList
        self.isAdGuardAnnoyancesList = true
        self.children = children
        self.isExpanded = false
    }
}

struct ChildFilterList {
    let genericFilterList: GenericFilterList
    var isAdGuardAnnoyancesList: Bool
    var isChild: Bool

    init(genericFilterList: GenericFilterList) {
        self.genericFilterList = genericFilterList
        self.isAdGuardAnnoyancesList = true
        self.isChild = true
    }
}
