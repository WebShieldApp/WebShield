import Foundation
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Developer").font(.headline)) {
                    Button("Reset Model") {
                        dataManager.resetModel()
                    }
                }.padding()
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
