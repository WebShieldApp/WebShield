import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        NavigationStack {
            SettingsForm()
                .navigationTitle("Settings")
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(.automatic)
                    }
                }
        }
    }
}

// MARK: - Settings Form
struct SettingsForm: View {
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        Form {
            developerSection()
        }
        .formStyle(.grouped)  // Grouped style is native on iOS/macOS
    }

    // MARK: - Developer Section
    private func developerSection() -> some View {
        Section(header: Text("Developer").font(.headline)) {
            Button(role: .destructive) {
                dataManager.resetModel()
            } label: {
                Label("Reset Model", systemImage: "arrow.counterclockwise.circle.fill")
            }
            .accessibilityLabel("Reset the application model")
        }
    }
}
