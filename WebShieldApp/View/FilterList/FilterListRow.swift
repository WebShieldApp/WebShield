//
//  FilterListRow.swift
//  WebShield
//
//  Created by Arjun on 2024-11-25.
//

import Foundation
import SwiftUI

struct FilterListRow: View {
    let filterList: FilterList
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext

    private var providerData: FilterListData? {
        FilterListProvider.filterListData.first { $0.name == filterList.name }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(filterList.name)
                        .font(.headline)

                    if let homepage = filterList.homepageURL,
                        let url = URL(string: homepage)
                    {
                        Button {
                            openURL(url)
                        } label: {
                            Label("Homepage", systemImage: "house")
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .help("Open Homepage")
                    }

                    if let urlString =
                        (providerData?.urlString ?? filterList.urlString),
                        let url = URL(string: urlString)
                    {
                        Button {
                            openURL(url)
                        } label: {
                            Label("View Source", systemImage: "eye")
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .help("View Filter Source")
                    }

                    if let infoURL = providerData?.informationURL,
                        let url = URL(string: infoURL)
                    {
                        Button {
                            openURL(url)
                        } label: {
                            Label("Information", systemImage: "info.circle")
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .help("View Filter Information")
                    }
                }

                Text(filterList.desc)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Text("\(filterList.totalRuleCount) rules")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text("Version \(filterList.version)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                // Add the last updated date
                Text(
                    "Last Updated: \(filterList.lastUpdated, formatter: itemFormatter)"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)

            Spacer()

            Toggle(
                "Enable Filter",
                isOn: Binding(
                    get: { filterList.isEnabled },
                    set: { newValue in
                        filterList.isEnabled = newValue
                        try? modelContext.save()
                    }
                )
            )
            .toggleStyle(.switch)
            .labelsHidden()
        }
    }
}

// Date formatter for a more readable date
private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()
