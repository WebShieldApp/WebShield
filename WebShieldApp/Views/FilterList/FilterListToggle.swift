//
//  FilterListToggle.swift
//  WebShieldApp
//
//  Created by Arjun on 2024-07-16.
//

import Foundation
import SwiftUI

struct FilterListToggle: View {
    @EnvironmentObject private var filterListManager: FilterListManager
    @State private var isOn: Bool
    let filterList: FilterList

    init(filterList: FilterList) {
        self.filterList = filterList
        self._isOn = State(initialValue: filterList.isSelected)
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading) {
                Text(filterList.name).font(.headline).foregroundStyle(.primary)
                Text(
                    "Last Updated: \(filterListManager.getLastUpdateDate(filter: filterList))"
                )
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onChange(of: isOn) {
            filterListManager.setSelection(
                for: filterList, isSelected: isOn)
        }
    }
}
