//
//  FilterList.swift
//  WebShieldApp
//
//

// Add Codable conformance
import Foundation
import SwiftUI

class FilterList: Identifiable, ObservableObject, Equatable, Codable, @unchecked
    Sendable
{
    let id: UUID
    @Published var name: String
    let url: URL
    let category: FilterListCategory
    @Published var isSelected: Bool
    @Published var desc: String
    @Published var version: String?
    let isAdGuardAnnoyancesList: Bool
    @Published var children: [FilterList]?
    @Published var isExpanded: Bool = false
    @Published var isChild: Bool = false

    init(
        name: String, url: URL, category: FilterListCategory,
        isSelected: Bool = false,
        description: String = "Description not available.",
        version: String? = nil,
        isAdGuardAnnoyancesList: Bool = false,
        children: [FilterList]? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.url = url
        self.category = category
        self.isSelected = isSelected
        self.desc = description
        self.version = version
        self.isAdGuardAnnoyancesList = isAdGuardAnnoyancesList
        self.children = children
    }

    // Equatable conformance
    static func == (lhs: FilterList, rhs: FilterList) -> Bool {
        lhs.id == rhs.id
    }

    // Codable conformance
    enum CodingKeys: String, CodingKey {
        case id, name, url, category, isSelected, desc, version,
            isAdGuardAnnoyancesList, children, isExpanded
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        url = try container.decode(URL.self, forKey: .url)
        category = try container.decode(
            FilterListCategory.self, forKey: .category)
        isSelected = try container.decode(Bool.self, forKey: .isSelected)
        desc = try container.decode(String.self, forKey: .desc)
        version = try container.decodeIfPresent(String.self, forKey: .version)
        isAdGuardAnnoyancesList = try container.decode(
            Bool.self, forKey: .isAdGuardAnnoyancesList)
        children = try container.decodeIfPresent(
            [FilterList].self, forKey: .children)
        isExpanded = try container.decode(Bool.self, forKey: .isExpanded)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(url, forKey: .url)
        try container.encode(category, forKey: .category)
        try container.encode(isSelected, forKey: .isSelected)
        try container.encode(desc, forKey: .desc)
        try container.encodeIfPresent(version, forKey: .version)
        try container.encode(
            isAdGuardAnnoyancesList, forKey: .isAdGuardAnnoyancesList)
        try container.encodeIfPresent(children, forKey: .children)
        try container.encode(isExpanded, forKey: .isExpanded)
    }

    // Additional methods
    func updateChildrenSelection(isSelected: Bool) {
        children?.forEach { child in
            if child.isSelected != isSelected {
                child.isSelected = isSelected
                child.updateChildrenSelection(isSelected: isSelected)
            }
        }
    }

    func updateSelectionBasedOnChildren() {
        guard let children = children else { return }
        let allSelected = children.allSatisfy { $0.isSelected }
        let noneSelected = children.allSatisfy { !$0.isSelected }

        if allSelected {
            if !isSelected {
                isSelected = true
            }
        } else if noneSelected {
            if isSelected {
                isSelected = false
            }
        } else {
            // Partially selected (if you want to handle this case)
            if isSelected {
                isSelected = false
            }
        }
    }
}
