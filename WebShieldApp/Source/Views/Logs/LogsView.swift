import ContentBlockerConverter
import SwiftUI
import os.log

struct LogsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    static let shared = LogsView()

    // Use a dynamic property to track logs
    @State private var logEntries: [String] = []

    var body: some View {
        NavigationStack {
            VStack {
                if logEntries.isEmpty {
                    // No logs placeholder
                    emptyStateView
                } else {
                    // Logs content
                    logsContentView
                }
            }
            .padding()
            .navigationTitle("Logs")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button {
                        copyLogs()
                    } label: {
                        Label("Copy Logs", systemImage: "doc.on.doc")
                    }
                }
            }
        }
        .onAppear {
            loadLogs()
        }
    }

    // MARK: - Subviews

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
                .textSelection(.enabled)  // Enable text selection
                .padding()
        }
        //        .background(
        //            RoundedRectangle(cornerRadius: 10)
        //                .fill(Color(.systemBackground))
        //                .shadow(radius: 2)
        //        )
    }

    // MARK: - Methods

    private func loadLogs() {
        logEntries = LogsView.logEntries
    }

    private func copyLogs() {
        let logs = logEntries.joined(separator: "\n")
        #if os(macOS)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(logs, forType: .string)
        #else
            UIPasteboard.general.string = logs
        #endif
    }

    // MARK: - Static Log Management Methods

    static private(set) var logEntries: [String] = []

    static func addLog(_ message: String) {
        print(message)
        logEntries.append(message)
        if logEntries.count > 1000 {
            logEntries.removeFirst(logEntries.count - 1000)
        }
    }

    static func logConversionStatistics(
        totalConvertedCount: Int, convertedCount: Int, errorsCount: Int, overLimit: Bool, for listName: String
    ) {
        addLog(
            """
            Conversion statistics for \(listName):
            - Total converted count: \(totalConvertedCount)
            - Converted count: \(convertedCount)
            - Errors count: \(errorsCount)
            - Over limit: \(overLimit)
            """)
    }

    static func logTotalStatistics(_ stats: TotalStats) {
        addLog(
            """
            Total conversion statistics:
            - Total converted count: \(stats.totalConvertedCount)
            - Converted count: \(stats.convertedCount)
            - Errors count: \(stats.errorsCount)
            - Lists over limit: \(stats.overLimit)
            """)
    }

    static func logProcessingStep(_ step: String, for listName: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        addLog("[\(timestamp)] \(listName): \(step)")
    }

    static func logRefreshStart() {
        addLog(
            """

            STARTING REFRESH

            """)
    }
}
