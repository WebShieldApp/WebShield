//
//  FilterListSection.swift
//  WebShield
//
//  Created by Arjun on 2024-07-16.
//

import Foundation

struct FilterListSection: Identifiable {
    let title: String
    let filterLists: [FilterList]
    let category: FilterListCategory
    var id: String { title }
}

