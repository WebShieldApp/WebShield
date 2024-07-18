//
//  ContentViewModel.swift
//  WebShieldApp
//
//  Created by Arjun on 2024-07-16.
//

import Foundation

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var selectedCategory: FilterListCategory? = .all
    let filterListManager: FilterListManager

    init(filterListManager: FilterListManager = FilterListManager()) {
        self.filterListManager = filterListManager
    }
}
