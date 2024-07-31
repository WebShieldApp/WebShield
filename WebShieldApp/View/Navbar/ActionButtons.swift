import SwiftUI

struct ActionButtons: View {
    let applyChanges: @MainActor @Sendable () async throws -> Void
    @StateObject var contentBlockerState: ContentBlockerState =
        ContentBlockerState()
    @State private var isUpdating = false

    var body: some View {
        Button("Refresh All") {
            Task {
                isUpdating = true
                do {
                    try await applyChanges()
                } catch {
                    print("Error applying changes: \(error)")
                }
                isUpdating = false
            }
        }
        .disabled(isUpdating)
    }
}
