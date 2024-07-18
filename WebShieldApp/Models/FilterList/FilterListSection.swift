//
//  FilterListSection.swift
//  WebShield
//
//  Created by Arjun on 2024-07-16.
//

import Foundation

struct FilterListSection: Identifiable {
    let id = UUID()
    let title: String
    let filterLists: [FilterList]
}
