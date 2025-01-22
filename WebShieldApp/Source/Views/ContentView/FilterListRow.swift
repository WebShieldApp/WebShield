import SwiftData
import SwiftUI

struct FilterListRow: View {
    let filterList: FilterList
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext

    private var providerData: FilterListData? {
        FilterListProvider.filterListData.first { $0.name == filterList.name }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 0) {
                Text(filterList.name)
                    .font(.headline)
                Spacer()
                Toggle(
                    "Enable Filter",
                    isOn: Binding(
                        get: { filterList.isEnabled },
                        set: { newValue in
                            filterList.isEnabled = newValue
                            filterList.needsRefresh = true
                            try? modelContext.save()
                        }
                    )
                )
                .toggleStyle(.switch)
                .labelsHidden()
            }
            actionButtons()

            Text(filterList.desc)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            footerInfo()

        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func footerInfo() -> some View {
        if filterList.downloaded {
            Text("\(filterList.totalRuleCount) rules")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text("Version: \(filterList.version)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text("Last Updated: \(filterList.lastUpdated, formatter: itemFormatter)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } else {
            Text("Never Downloaded!")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text("Never Updated!")
                .font(.footnote)
                .foregroundStyle(.secondary)

        }
    }

    @ViewBuilder
    private func actionButtons() -> some View {
        HStack(spacing: 8) {
            if let homepage = filterList.homepageUrl, let url = URL(string: homepage) {
                createButton(url: url, systemImage: "house", helpText: "Open Homepage")
            }

            if let downloadUrl = (providerData?.downloadUrl ?? filterList.downloadUrl), let url = URL(string: downloadUrl) {
                createButton(url: url, systemImage: "eye", helpText: "View Filter Source")
            }

            if let infoURL = providerData?.informationUrl, let url = URL(string: infoURL) {
                createButton(url: url, systemImage: "info.circle", helpText: "View Filter Information")
            }
        }
    }

    private let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    @ViewBuilder
    private func createButton(url: URL, systemImage: String, helpText: String) -> some View {
        Button {
            openURL(url)
        } label: {
            Label(helpText, systemImage: systemImage)
                .labelStyle(.iconOnly)
            //                .foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
        .help(helpText)
    }
}
