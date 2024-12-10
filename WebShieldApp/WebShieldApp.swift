import SwiftData
import SwiftUI

@main
struct WebShieldApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(
                    for: FilterList.self,
                    isAutosaveEnabled: true)
        }
    }
}
