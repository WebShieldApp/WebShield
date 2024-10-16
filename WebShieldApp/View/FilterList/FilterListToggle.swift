//
//  FilterListToggle.swift
//  WebShieldApp
//

import SwiftUI

struct FilterListToggle: View {
    @EnvironmentObject var filterListManager: FilterListManager
    @ObservedObject var filterList: FilterList
    let deleteAction: (() -> Void)?

    init(filterList: FilterList, deleteAction: (() -> Void)? = nil) {
        self.filterList = filterList
        self.deleteAction = deleteAction
    }

    var body: some View {
        if let children = filterList.children, !children.isEmpty {
            DisclosureGroup(isExpanded: $filterList.isExpanded) {
                ForEach(children) { child in
                    FilterListToggle(filterList: child)
                        .padding(.leading)
                        .onChange(of: child.isSelected) {
                            filterList.updateSelectionBasedOnChildren()
                        }
                }
            } label: {
                Toggle(
                    isOn: Binding(
                        get: { filterList.isSelected },
                        set: { newValue in
                            filterList.isSelected = newValue
                            filterList.updateChildrenSelection(
                                isSelected: newValue)
                        }
                    )
                ) {
                    VStack(alignment: .leading) {
                        Text(filterList.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        if let version = filterList.version {
                            Text("Version: \(version)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(filterList.desc)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(
                            "Last Updated: \(filterListManager.getLastUpdateDate(filter: filterList))"
                        )
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }
                }
            }
        } else {
            HStack {
                Toggle(isOn: $filterList.isSelected) {
                    VStack(alignment: .leading) {
                        Text(filterList.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        if let version = filterList.version {
                            Text("Version: \(version)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(filterList.desc)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .contextMenu {
                if filterList.category == .custom {
                    Button(role: .destructive) {
                        deleteAction?()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
}
