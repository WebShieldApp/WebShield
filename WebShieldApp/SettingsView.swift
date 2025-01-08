import Foundation
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    private let filterListProcessor = FilterListProcessor()
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Developer")) {
                    Button("Reset Model") {
                        dataManager.resetModel()
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
