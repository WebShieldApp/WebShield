//
//  ContentViewModel.swift
//  WebShieldApp
//
//  Created by Arjun on 2024-07-16.
//

import Foundation
import SwiftData

final class ContentViewModel: ObservableObject {
    @Published var selectedCategory: FilterListCategory = .all

    @MainActor
    init(context: ModelContext) {

    }
}
