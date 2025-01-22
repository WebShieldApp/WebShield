import SwiftUI

struct LogsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var logEntries: [String] = []

    var body: some View {
        NavigationStack {
            VStack {
                if logEntries.isEmpty {
                    emptyStateView
                } else {
                    logsContentView
                }
            }
            .padding()
            .navigationTitle("Logs")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .automatic) {
                    Button(action: copyLogs) {
                        Label("Copy Logs", systemImage: "doc.on.doc")
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        Task {
                            await clearLogs()
                        }
                    }) {
                        Label("Clear Logs", systemImage: "trash")
                    }
                }

            }
        }
        .onAppear {
            Task {
                // Fetch logs from the actor
                self.logEntries = await WebShieldLogger.shared.allLogs()
            }
        }
    }

    private var emptyStateView: some View {
        VStack {
            Spacer()
            Text("No Logs Yet")
                .font(.body)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .multilineTextAlignment(.center)
    }

    private var logsContentView: some View {
        ScrollView {
            Text(logEntries.joined(separator: "\n"))
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding()
        }
    }

    private func copyLogs() {
        let logsText = logEntries.joined(separator: "\n")
        #if os(macOS)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(logsText, forType: .string)
        #else
            UIPasteboard.general.string = logsText
        #endif
    }

    private func clearLogs() async {
        await WebShieldLogger.shared.clearLogs()
        logEntries = await WebShieldLogger.shared.allLogs()
    }
}
