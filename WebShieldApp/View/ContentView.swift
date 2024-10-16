//
//  ContentView.swift
//  WebShieldApp
//

import SwiftUI

struct ContentView: View {
    @State private var selectedCategory: FilterListCategory? = .all
    @StateObject private var filterListManager = FilterListManager()

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .environmentObject(filterListManager)
        } detail: {
            DetailView(selectedCategory: selectedCategory)
                .environmentObject(filterListManager)
        }
    }
}
