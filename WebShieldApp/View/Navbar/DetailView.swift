//
//  DetailView.swift
//  WebShieldApp
//


import SwiftUI

struct DetailView: View {

    @EnvironmentObject private var filterListManager: FilterListManager
    let selectedCategory: FilterListCategory?

    var body: some View {
        NavigationStack {
            if let category = selectedCategory {
                FilterListView(category: category).environmentObject(
                    filterListManager)
            } else {
                Text("Select a category")
            }
        }.environmentObject(filterListManager)
    }
}
