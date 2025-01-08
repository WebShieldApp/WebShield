import Foundation
import SafariServices
import SwiftData
import SwiftUI

@main
struct WebShieldApp: App {
    @StateObject private var dataManager = DataManager()

    var body: some Scene {

        WindowGroup {
            ContentView()
                .modelContainer(
                    for: [FilterList.self],
                    isAutosaveEnabled: true
                )
                .environmentObject(dataManager)
                .onAppear {
                    dataManager.seedDataIfNeeded()
                }
                .frame(minWidth: 900, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)
        }

            //        Settings {
            //            SettingsView()
            //                .modelContainer(
            //                    for: FilterList.self,
            //                    isAutosaveEnabled: true)
            //        }
    }
}
