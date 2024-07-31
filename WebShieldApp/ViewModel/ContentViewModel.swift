//
//  ContentViewModel.swift
//  WebShieldApp
//
//  Created by Arjun on 2024-07-16.
//

import Foundation

final class ContentViewModel: ObservableObject {
    @Published var selectedCategory: FilterListCategory? = .all
    let filterListManager: FilterListManager

    @MainActor
    init(filterListManager: FilterListManager = FilterListManager()) {
        self.filterListManager = filterListManager
    }
}
