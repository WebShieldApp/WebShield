//
//  FilterListViewModel.swift
//  WebShield
//
//  Created by Arjun on 2024-07-16.
//
import Foundation
import SwiftUI

@MainActor
final class FilterListViewModel: ObservableObject {
    @Published var sections: [FilterListSection] = []
    private let category: FilterListCategory

    init(category: FilterListCategory) {
        self.category = category
        loadSections()
    }

    private func loadSections() {
        if category == .all {
            sections = FilterListCategory.allCases.dropFirst().map { category in
                FilterListSection(
                    title: category.rawValue,
                    filterLists: FilterListProvider.filterLists(for: category))
            }
        } else {
            sections = [
                FilterListSection(
                    title: category.rawValue,
                    filterLists: FilterListProvider.filterLists(for: category))
            ]
        }
    }
}
