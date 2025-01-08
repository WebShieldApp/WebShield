import SwiftData
import SwiftUI

@main
struct WebShieldApp: App {
    @StateObject private var dataManager = DataManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(dataManager.container)
                .environmentObject(dataManager)
                .onAppear {
                    dataManager.seedDataIfNeeded()
                }
                .frame(minWidth: 900, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)
        }
    }
}
