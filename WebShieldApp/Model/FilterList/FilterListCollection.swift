//
//  FilterListCollection.swift
//  WebShield
//
//  Created by Arjun on 2024-10-25.
//

struct FilterListCollection {
    typealias SetType = [FilterList]

    private var filterLists = SetType()

    init(filterLists: SetType) {
        self.filterLists = filterLists
    }
}

extension FilterListCollection: Collection {
    typealias Index = SetType.Index
    typealias Element = SetType.Element

    var startIndex: Index {
        return filterLists.startIndex
    }

    var endIndex: Index {
        return filterLists.endIndex
    }

    // Required subscript, based on a dictionary index
    subscript(index: Index) -> Iterator.Element {
        get { return filterLists[index] }
    }

    // Method that returns the next index when iterating
    func index(after i: Index) -> Index {
        return filterLists.index(after: i)
    }

}
