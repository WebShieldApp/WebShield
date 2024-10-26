//
//  FilterListCollection.swift
//  WebShield
//
//  Created by Arjun on 2024-10-25.
//

struct FilterListCollection {
    typealias DictionaryType = [FilterList]

    private var filterLists = DictionaryType()

    init(filterLists: DictionaryType) {
        self.filterLists = filterLists
    }
}
