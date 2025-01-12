//
//  StatsView.swift
//  WebShield
//
//  Created by Arjun on 1/11/25.
//

import Foundation
import SwiftData
import SwiftUI

struct StatsView: View {
    @Query(sort: \FilterList.order, order: .forward) private var filterLists: [FilterList]
    var filteredLists: [FilterList]

    var body: some View {
        Section {
            HStack {
                // Shield
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.blue.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: "shield")
                        .imageScale(.medium)
                        .foregroundStyle(.blue)
                        .fontWeight(.semibold)
                }

                Grid(horizontalSpacing: 10, verticalSpacing: 4) {
                    GridRow {
                        Text("\(enabledCount)")
                            .font(.title2)
                            .bold()
                            .gridColumnAlignment(.leading)
                        Text("\(totalRules)")
                            .font(.title2)
                            .bold()
                            .gridColumnAlignment(.leading)
                    }
                    GridRow {
                        Text("Enabled")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .gridColumnAlignment(.leading)
                        Text("Rules")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .gridColumnAlignment(.leading)
                    }
                }
                .padding()

                Spacer()
            }
        }

    }

    private var enabledCount: Int {
        filteredLists.filter { $0.isEnabled }.count
    }

    private var totalRules: Int {
        filteredLists.filter { $0.isEnabled }.reduce(0) {
            $0 + $1.totalRuleCount
        }
    }
}
