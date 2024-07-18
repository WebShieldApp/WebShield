//
//  CategoryNav.swift
//  WebShield
//
//  Created by Arjun on 2024-07-16.
//
import Foundation
import SwiftUI

struct CategoryNav: View {
    let category: FilterListCategory

    var body: some View {
        Label {
            Text(category.rawValue)
        } icon: {
            Image(systemName: category.systemImage)
        }
    }
}
