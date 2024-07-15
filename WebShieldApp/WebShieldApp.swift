//
//  WebShieldApp.swift
//  WebShield
//
//  Created by Arjun on 24/6/24.
//

import SwiftData
import SwiftUI

@main
struct WebShieldApp: App {
    @StateObject private var blockListManager = FilterListManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(
                for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(blockListManager)
        }
        .modelContainer(sharedModelContainer)
    }

}
