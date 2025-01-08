@preconcurrency import ContentBlockerConverter
import Foundation
import SwiftData
import SwiftUI

@MainActor
struct ImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var urls: [String] = [""]
    @State private var isImporting = false
    let filterListProcessor = FilterListProcessor()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Import Filter Lists")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderless)
            }
            .padding()
            //            .background(Color(.systemBackground))

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Enter filter list URLs (one per line)")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    VStack(spacing: 8) {
                        ForEach(urls.indices, id: \.self) { index in
                            HStack {
                                TextField(
                                    "Filter List URL",
                                    text: $urls[index]
                                )
                                .textFieldStyle(.roundedBorder)
                                .disableAutocorrection(true)
                                //                                .textInputAutocapitalization(.never)

                                if urls.count > 1 {
                                    Button(role: .destructive) {
                                        urls.remove(at: index)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    Button {
                        urls.append("")
                    } label: {
                        Label("Add URL", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }

            Divider()

            // Footer
            HStack {
                Spacer()
                Button("Import", action: importFilterLists)
                    .buttonStyle(.borderedProminent)
                    .disabled(isImporting || urls.allSatisfy { $0.isEmpty })
            }
            .padding()
            #if targetEnvironment(macCatalyst) || os(iOS)
                .background(Color(.systemBackground))
            #else
                .background(Color(.textBackgroundColor))
            #endif
        }
        //        .frame(width: 500, height: 400)
    }

    private func importFilterLists() {
        Task {
            isImporting = true
            defer { isImporting = false }

            let validUrls = urls.filter { !$0.isEmpty }
                .compactMap {
                    URL(string: $0.trimmingCharacters(in: .whitespaces))
                }

            for url in validUrls {
                do {
                    // Download and extract metadata
                    let data = try await filterListProcessor.downloadFilterList(
                        from: url)
                    guard let content = String(data: data, encoding: .utf8)
                    else {
                        throw FilterListError.invalidData
                    }

                    // Extract metadata
                    var title = url.lastPathComponent
                    var version = "0.0.0"
                    var description = "Imported filter list"

                    for line in content.components(separatedBy: .newlines) {
                        if line.hasPrefix("! Title:") {
                            title = line.replacingOccurrences(
                                of: "! Title:", with: ""
                            )
                            .trimmingCharacters(in: .whitespaces)
                        } else if line.hasPrefix("! Version:") {
                            version = line.replacingOccurrences(
                                of: "! Version:", with: ""
                            )
                            .trimmingCharacters(in: .whitespaces)
                        } else if line.hasPrefix("! Description:") {
                            description = line.replacingOccurrences(
                                of: "! Description:", with: ""
                            )
                            .trimmingCharacters(in: .whitespaces)
                        }
                    }

                    // Create new filter list
                    let filterList = FilterList(
                        name: title,
                        version: version,
                        desc: description,
                        category: .custom,
                        isEnabled: true,
                        downloaded: false
                    )
                    filterList.urlString = url.absoluteString

                    modelContext.insert(filterList)
                    LogsView.logProcessingStep(
                        "Added new filter list: \(title)",
                        for: "Import"
                    )
                } catch {
                    LogsView.logProcessingStep(
                        "Failed to import: \(error.localizedDescription)",
                        for: url.absoluteString
                    )
                }
            }

            do {
                try modelContext.save()
                LogsView.logProcessingStep(
                    "Successfully imported \(validUrls.count) filter lists",
                    for: "Import"
                )
            } catch {
                LogsView.logProcessingStep(
                    "Failed to save filter lists: \(error.localizedDescription)",
                    for: "Import"
                )
            }

            dismiss()
        }
    }
}
