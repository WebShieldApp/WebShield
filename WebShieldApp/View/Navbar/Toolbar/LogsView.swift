import SwiftUI

struct LogsView: View {
    let logs: String
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var showCopyAlert = false

    var body: some View {
        #if os(iOS) || os(tvOS) || os(visionOS)
            NavigationView {
                content
                    .navigationTitle("Logs")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        // Close button
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Close") {
                                dismiss()
                            }
                        }
                        // Copy button
                        if hasLogs {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: {
                                    copyLogsToClipboard()
                                }) {
                                    Image(systemName: "doc.on.doc")
                                }
                            }
                        }
                    }
            }
            .navigationViewStyle(StackNavigationViewStyle())
        #endif
        //        #else
        //            VStack {
        //                content
        //                HStack {
        //                    Spacer()
        //                    Button("Close") {
        //                        dismiss()
        //                    }
        //                    .padding()
        //                }
        //            }
        //            .frame(minWidth: 400, minHeight: 300)
        //            .toolbar {
        //                if hasLogs {
        //                    ToolbarItem {
        //                        Button(action: {
        //                            copyLogsToClipboard()
        //                        }) {
        //                            Image(systemName: "doc.on.doc")
        //                        }
        //                    }
        //                }
        //            }
        //        #endif
        #if os(macOS)
            VStack {
                content
                HStack {
                    Button(action: {
                        copyLogsToClipboard()
                    }) {
                        Image(systemName: "doc.on.doc")
                    }
                    Spacer()
                    Button("Close") {
                        dismiss()
                    }
                }
                .padding()
            }
            .frame(minWidth: 400, minHeight: 300)
        #endif
    }

    private var content: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search logs", text: $searchText)
            }
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            .padding()

            // Logs content
            if hasLogs {
                ScrollView {
                    Text(filteredLogs)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .background(Color(Color.background))
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No Logs")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .multilineTextAlignment(.center)  // Center the text
            }
        }
    }

    private var filteredLogs: String {
        if searchText.isEmpty {
            return logs
        } else {
            return logs.split(separator: "\n")
                .filter { $0.localizedCaseInsensitiveContains(searchText) }
                .joined(separator: "\n")
        }
    }

    private var hasLogs: Bool {
        !filteredLogs.isEmpty
    }

    private func copyLogsToClipboard() {
        #if os(iOS)
            UIPasteboard.general.string = filteredLogs
        #elseif os(macOS)
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(filteredLogs, forType: .string)
        #endif
        showCopyAlert = true
    }
}
