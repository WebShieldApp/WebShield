import ContentBlockerConverter
import SwiftData
import SwiftUI

struct ImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var urlStrings: [String] = [""]
    @State private var isImporting = false
    @State private var showError = false
    @State private var error: Error?

    let filterListProcessor = FilterListProcessor()

    var body: some View {
        NavigationStack {
            Form {
                instructionsSection
                urlsInputSection
            }
            .formStyle(.grouped)
            .navigationTitle("Import Filter Lists")
            .toolbar {
                ToolbarItemGroup(placement: .cancellationAction) {
                    cancelButton
                }
                ToolbarItemGroup(placement: .confirmationAction) {
                    importButton
                }
            }
            .disabled(isImporting)
            .alert("Error", isPresented: $showError, presenting: error) { error in
                Button("OK") {}
            } message: { error in
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - Subviews

    private var instructionsSection: some View {
        Section {
            Text(
                "Enter the URLs of filter lists to import, each on a new line. Ensure the URLs point directly to valid filter list files."
            )
        }
    }

    private var urlsInputSection: some View {
        Section(header: Text("Filter List URLs")) {
            ForEach(urlStrings.indices, id: \.self) { index in
                urlInputRow(for: index)
            }
            addUrlButton
        }
    }

    private func urlInputRow(for index: Int) -> some View {
        HStack {
            TextField("Enter URL", text: $urlStrings[index])
                .autocorrectionDisabled(true)
            if urlStrings.count > 1 {
                removeUrlButton(at: index)
            }
        }
    }

    private func removeUrlButton(at index: Int) -> some View {
        Button(role: .destructive) {
            urlStrings.remove(at: index)
        } label: {
            Image(systemName: "minus.circle.fill")
        }
        .buttonStyle(.borderless)
        .foregroundColor(.red)
    }

    private var addUrlButton: some View {
        Button {
            urlStrings.append("")
        } label: {
            Label("Add URL", systemImage: "plus.circle.fill")
        }
    }

    private var cancelButton: some View {
        Button("Cancel") {
            dismiss()
        }
    }

    private var importButton: some View {
        Group {
            if isImporting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Button("Import") {
                    Task {
                        await importFilterLists()
                    }
                }
                .disabled(urlStrings.allSatisfy { $0.isEmpty })
            }
        }
    }

    // MARK: - Import Logic

    private func importFilterLists() async {
        let validUrls = urlStrings.compactMap { urlString in
            URL(string: urlString.trimmingCharacters(in: .whitespaces))
        }

        guard !validUrls.isEmpty else {
            self.error = FilterListError.invalidURL
            showError = true
            return
        }

        isImporting = true
        defer {
            isImporting = false
            resetUrlStrings()  // Reset the URLs after import
        }

        for url in validUrls {
            do {
                let data = try await filterListProcessor.downloadFilterList(from: url)
                let content = try parseFilterListData(data)
                let filterList = try createFilterList(from: content, url: url)
                modelContext.insert(filterList)
                LogsView.logProcessingStep("Added new filter list: \(filterList.name)", for: "Import")
            } catch {
                self.error = error
                showError = true
                LogsView.logProcessingStep("Failed to import: \(error.localizedDescription)", for: url.absoluteString)
                return  // Stop importing on the first error
            }
        }

        do {
            try modelContext.save()
            LogsView.logProcessingStep("Successfully imported \(validUrls.count) filter lists", for: "Import")
            dismiss()
        } catch {
            self.error = error
            showError = true
            LogsView.logProcessingStep("Failed to save filter lists: \(error.localizedDescription)", for: "Import")
        }
    }

    private func parseFilterListData(_ data: Data) throws -> String {
        guard let content = String(data: data, encoding: .utf8) else {
            throw FilterListError.invalidData
        }
        return content
    }

    private func createFilterList(from content: String, url: URL) throws -> FilterList {
        var title = url.lastPathComponent
        var version = "0.0.0"
        var description = "Imported filter list"

        for line in content.components(separatedBy: .newlines) {
            if line.hasPrefix("! Title:") {
                title = line.replacingOccurrences(of: "! Title:", with: "")
                    .trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("! Version:") {
                version = line.replacingOccurrences(of: "! Version:", with: "")
                    .trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("! Description:") {
                description = line.replacingOccurrences(of: "! Description:", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }
        }

        return FilterList(
            name: title,
            version: version,
            desc: description,
            category: .custom,
            isEnabled: true,
            urlString: url.absoluteString,
            downloaded: false
        )
    }

    private func resetUrlStrings() {
        urlStrings = [""]
    }
}
