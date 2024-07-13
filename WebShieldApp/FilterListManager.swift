import Combine
import ContentBlockerConverter
import Foundation
import SafariServices

class FilterListManager: ObservableObject {
    @Published var filterLists: [FilterList] = []
    var contentBlockerState = ContentBlockerState(
        withIdentifier: "me.arjuna.WebShield.ContentBlocker"
    )

    init() {
        loadFilterLists()
    }

    func loadFilterLists() {
        // Add your predefined block lists here
        filterLists = [
            FilterList(
                name: "AdGuard Base filter",
                url: URL(
                    string:
                        "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/2_optimized.txt"
                )!,
                category: .ads,
                isSelected: true
            ),
            FilterList(
                name: "AdGuard Tracking Protection filter",
                url: URL(
                    string:
                        "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/4_optimized.txt"
                )!,
                category: .privacy,
                isSelected: true
            ),

            FilterList(
                name: "AdGuard Annoyances filter",
                url: URL(
                    string:
                        "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/14_optimized.txt"
                )!,
                category: .annoyances),
            FilterList(
                name: "AdGuard Social Media filter",
                url: URL(
                    string:
                        "https://github.com/AdguardTeam/FiltersRegistry/blob/master/platforms/extension/safari/filters/3_optimized.txt"
                )!,
                category: .annoyances),
            FilterList(
                name: "Fanboy's Annoyances filter",
                url: URL(
                    string:
                        "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/122_optimized.txt"
                )!,
                category: .annoyances),
            FilterList(
                name: "EasyPrivacy",
                url: URL(
                    string:
                        "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/118_optimized.txt"
                )!,
                category: .privacy,
                isSelected: true),
            FilterList(
                name: "Online Malicious URL Blocklist",
                url: URL(
                    string:
                        "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/208_optimized.txt"
                )!,
                category: .security,
                isSelected: true),
            FilterList(
                name: "Peter Lowe's Blocklist",
                url: URL(
                    string:
                        "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/204_optimized.txt"
                )!,
                category: .multipurpose,
                isSelected: true),
            FilterList(
                name: "Hagezi Pro mini",
                url: URL(
                    string:
                        "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.mini.txt"
                )!,
                category: .multipurpose,
                isSelected: true),
            FilterList(
                name: "d3Host List by d3ward",
                url: URL(
                    string:
                        "https://raw.githubusercontent.com/d3ward/toolz/master/src/d3host.adblock"
                )!,
                category: .multipurpose,
                isSelected: true),
            FilterList(
                name: "Anti-Adblock List",
                url: URL(
                    string:
                        "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/207_optimized.txt"
                )!,
                category: .multipurpose,
                isSelected: true),
            FilterList(
                name: "AdGuard Experimental filter",
                url: URL(
                    string:
                        "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/5_optimized.txt"
                )!,
                category: .experimental),
        ]
    }

    func applyChanges(completion: @escaping () -> Void) {
        let selectedLists = filterLists.filter { $0.isSelected }
        convertFilterLists(selectedLists) {
            completion()
        }
    }

    func refreshAndReloadContentBlocker(completion: @escaping () -> Void) {
        reloadContentBlocker {
            self.refreshContentBlocker {
                completion()
            }
        }
    }

    func filterLists(for category: FilterListCategory) -> [FilterList]? {
        filterLists.filter { $0.category == category }
    }

    private func refreshContentBlocker(completion: @escaping () -> Void) {
        print("Preparing to refresh content blocker...")
        // Add a delay to ensure file writing is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("Initiating content blocker refresh...")
            self.contentBlockerState.refreshContentBlockerState()
            completion()
        }
    }

    private func convertFilterLists(
        _ lists: [FilterList], completion: @escaping () -> Void
    ) {
        let dispatchGroup = DispatchGroup()
        var allRules: [String] = []

        for list in lists {
            dispatchGroup.enter()
            URLSession.shared.dataTask(with: list.url) {
                data, response, error in
                defer { dispatchGroup.leave() }

                guard let data = data, error == nil else {
                    print(
                        "Error downloading \(list.name): \(error?.localizedDescription ?? "Unknown error")"
                    )
                    return
                }

                if let content = String(data: data, encoding: .utf8) {
                    let rules = self.parseRules(content)
                    allRules.append(contentsOf: rules)
                }
            }.resume()
        }

        dispatchGroup.notify(queue: .main) {
            self.saveRulesToFile(allRules) {
                completion()
            }
        }
    }

    private func parseRules(_ content: String) -> [String] {
        return content.components(separatedBy: .newlines)
            .filter { !$0.hasPrefix("!") && !$0.hasPrefix("[") && !$0.isEmpty }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    private func saveRulesToFile(
        _ rules: [String], completion: @escaping () -> Void
    ) {
        print("Starting rule conversion and saving process...")
        do {
            let converter = ContentBlockerConverter()
            print("Converting \(rules.count) rules...")
            let result = converter.convertArray(
                rules: rules,
                safariVersion: .safari16_4,  // Use the appropriate version for your target
                optimize: true,
                advancedBlocking: true
            )
            let converted = result.converted
            print(
                "Conversion completed. Converted rules count: \(result.convertedCount)"
            )
            if !converted.isEmpty {
                if let containerURL = getSharedContainerURL() {
                    let blockerListfileURL = containerURL.appending(
                        path: "blockerList.json")
                    print(
                        "Writing converted rules to file: \(blockerListfileURL.path)"
                    )
                    try converted.write(
                        to: blockerListfileURL, atomically: true,
                        encoding: .utf8)
                    print("Successfully wrote blockerList.json")
                    let advancedBlockingFileURL = containerURL.appending(
                        path: "advancedBlocking.json")
                    print(
                        "Writing advanced blocking rules to file: \(advancedBlockingFileURL.path)"
                    )
                    try result.advancedBlocking!
                        .write(
                            to: advancedBlockingFileURL, atomically: true,
                            encoding: .utf8)
                    print("Successfully wrote advancedBlockingFileURL.json")
                    //                    print("First 1000 characters of converted rules:")
                    //                    print(String(converted.prefix(1000)))

                    if let attributes = try? FileManager.default
                        .attributesOfItem(atPath: blockerListfileURL.path),
                        let fileSize = attributes[.size] as? Int64
                    {
                        print("File size: \(fileSize) bytes")
                        if fileSize > 2_000_000 {
                            print(
                                "WARNING: File size exceeds 2MB limit for Safari content blockers!"
                            )
                        }
                    }

                    // Reload the Content Blocker
                    reloadContentBlocker {
                        completion()
                    }
                } else {
                    print("ERROR: Unable to access shared container")
                }
            } else {
                print("ERROR: Conversion resulted in empty rules")
            }

            print("Conversion statistics:")
            print("- Total converted count: \(result.totalConvertedCount)")
            print("- Converted count: \(result.convertedCount)")
            print("- Errors count: \(result.errorsCount)")
            print("- Over limit: \(result.overLimit)")

            if result.errorsCount > 0 {
                print(
                    "WARNING: Some rules could not be converted. Check your input rules for compatibility."
                )
            }

        } catch {
            print("ERROR: Failed to create or save JSON")
            print("Error details: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("Error domain: \(nsError.domain)")
                print("Error code: \(nsError.code)")
                if let reason = nsError.localizedFailureReason {
                    print("Failure reason: \(reason)")
                }
                if let suggestion = nsError.localizedRecoverySuggestion {
                    print("Recovery suggestion: \(suggestion)")
                }
            }
        }
    }

    private func reloadContentBlocker(completion: @escaping () -> Void) {
        print("Preparing to reload content blocker...")
        // Add a delay to ensure file writing is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("Initiating content blocker reload...")
            self.contentBlockerState.reloadContentBlocker()
            completion()
        }
    }

    private func getSharedContainerURL() -> URL? {
        let container = "G5S45S77DF.me.arjuna.WebShield"
        return FileManager.default
            .containerURL(
                forSecurityApplicationGroupIdentifier: container
            )
    }
}
