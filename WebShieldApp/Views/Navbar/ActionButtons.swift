//
//  ActionButtons.swift
//  WebShield
//
//  Created by Arjun on 2024-07-16.
//
import SwiftUI

struct ActionButtons: View {
    let applyChanges: @MainActor @Sendable () async throws -> Void
    @State private var isUpdating = false

    var body: some View {
        HStack {
            Button("Disable") {
                print("Toggle") // DUMMY
            }
            Button("Refresh All") {
                Task {
                    isUpdating = true
                    do {
                        try await applyChanges()
                    } catch {
                        // Handle error
                        print("Error applying changes: \(error)")
                    }
                    isUpdating = false
                }
            }
            .disabled(isUpdating)
        }
    }
}
