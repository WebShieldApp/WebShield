// LogsView.swift

import ContentBlockerConverter
import Foundation
import SwiftUI
import os.log

@MainActor
struct LogsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    static let shared = LogsView()
    private static var logEntries: [String] = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Logs")
                    .font(.headline)
                Spacer()
                Button(action: copyLogs) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderless)
            }
            .padding()
            .background(Color(.windowBackgroundColor))

            Divider()

            // Log content
            ScrollView {
                Text(Self.logEntries.joined(separator: "\n"))
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color(.textBackgroundColor))
        }
        .frame(width: 600, height: 400, alignment: .top)
    }

    private func copyLogs() {
        #if os(macOS)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(
                Self.logEntries.joined(separator: "\n"),
                forType: .string
            )
        #else
            UIPasteboard.general.string = Self.logEntries.joined(
                separator: "\n")
        #endif
    }

    // Static methods to add logs
    static func logConversionStatistics(
        totalConvertedCount: Int,
        convertedCount: Int,
        errorsCount: Int,
        overLimit: Bool,
        for listName: String
    ) {
        let message = """

            Conversion statistics for \(listName):
            - Total converted count: \(totalConvertedCount)
            - Converted count: \(convertedCount)
            - Errors count: \(errorsCount)
            - Over limit: \(overLimit)

            """
        addLog(message)
    }

    static func logTotalStatistics(_ stats: TotalStats) {
        let message = """

            Total conversion statistics:
            - Total converted count: \(stats.totalConvertedCount)
            - Converted count: \(stats.convertedCount)
            - Errors count: \(stats.errorsCount)
            - Lists over limit: \(stats.overLimit)

            """
        addLog(message)
    }

    static func logProcessingStep(_ step: String, for listName: String) {
        let timestamp = DateFormatter.localizedString(
            from: Date(),
            dateStyle: .none,
            timeStyle: .medium
        )
        addLog("[\(timestamp)] \(listName): \(step)")
    }

    static func logRefreshStart() {
        let message = """


            ==========================================
                        STARTING REFRESH
            ==========================================

            """
        addLog(message)
    }

    private static func addLog(_ message: String) {
        print("\(message)")
        logEntries.append(message)
        if logEntries.count > 1000 {
            logEntries.removeFirst(logEntries.count - 1000)
        }
    }
}
