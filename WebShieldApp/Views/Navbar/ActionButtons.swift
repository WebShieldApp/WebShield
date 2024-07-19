import SwiftUI

struct ActionButtons: View {
    let applyChanges: @MainActor @Sendable () async throws -> Void
    @StateObject var contentBlockerState: ContentBlockerState = ContentBlockerState()
    @State private var isUpdating = false

    var body: some View {
        HStack {
            // TODO: BUG FIX, Toggling content blocker is messed up
            Button(contentBlockerState.isEnabled ? "Disable" : "Enable") {
                Task {
                    await contentBlockerState.toggleContentBlocker()
                }
            }
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
}
