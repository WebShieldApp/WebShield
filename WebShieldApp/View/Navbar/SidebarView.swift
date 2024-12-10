//
//  SidebarView.swift
//  WebShieldApp
//

import SwiftData
import SwiftUI

struct SidebarView: View {
    @Binding var selectedCategory: FilterListCategory
    @Query(sort: \FilterList.categoryString, order: .forward) var filterLists:
        [FilterList]
    @State private var showingImport = false

    // 1. Use a regular List without selection binding
    var body: some View {
        VStack {
            Text("Categories")
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.top, .leading])
            List {
                ForEach(
                    [FilterListCategory.all, .regional, .custom], id: \.self
                ) { category in
                    NavigationLink(destination: destinationView(for: category))
                    {
                        HStack {
                            Image(systemName: category.systemImage)
                            Text(category.rawValue)
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    }
                }
            }
            .listStyle(SidebarListStyle())

            Spacer()  // Push the button to the bottom

            // 2. Import button outside the List
            Button(action: {
                showingImport = true
            }) {
                Label("Import", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThickMaterial)
            .cornerRadius(10)
            .padding(.bottom, 8)
        }
        .navigationTitle("")  // Optional: Remove the navigation title if it's not needed here
        .sheet(isPresented: $showingImport) {
            ImportView()
        }
    }

    // Helper function to create destination views
    private func destinationView(for category: FilterListCategory) -> some View
    {
        FilterListView(category: category)
    }
}
