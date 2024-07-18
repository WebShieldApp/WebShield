import Foundation

enum FilterListProvider {
    static func filterLists(for category: FilterListCategory) -> [FilterList] {
        switch category {
        case .all: return allFilterLists
        case .ads: return allFilterLists.filter { $0.category == .ads }
        case .privacy: return allFilterLists.filter { $0.category == .privacy }
        case .security:
            return allFilterLists.filter { $0.category == .security }
        case .multipurpose:
            return allFilterLists.filter { $0.category == .multipurpose }
        case .cookies: return allFilterLists.filter { $0.category == .cookies }
        case .social: return allFilterLists.filter { $0.category == .social }
        case .annoyances:
            return allFilterLists.filter { $0.category == .annoyances }
        case .regional:
            return allFilterLists.filter { $0.category == .regional }
        case .experimental:
            return allFilterLists.filter { $0.category == .experimental }
        case .custom: return allFilterLists.filter { $0.category == .custom }
        }
    }

    static var allFilterLists: [FilterList] {
        [
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
                category: .annoyances
            ),
            FilterList(
                name: "AdGuard Cookie Notices filter",
                url: URL(
                    string:
                        "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/18_optimized.txt"
                )!,
                category: .cookies
            ),
            FilterList(
                name: "AdGuard Social Media filter",
                url: URL(
                    string:
                        "https://github.com/AdguardTeam/FiltersRegistry/blob/master/platforms/extension/safari/filters/3_optimized.txt"
                )!,
                category: .social
            ),
            FilterList(
                name: "Fanboy's Annoyances filter",
                url: URL(
                    string:
                        "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/122_optimized.txt"
                )!,
                category: .annoyances
            ),
            FilterList(
                name: "Adblock List for Albania",
                url: URL(
                    string:
                        "https://raw.githubusercontent.com/AnXh3L0/blocklist/master/albanian-easylist-addition/Albania.txt"
                )!,
                category: .regional
            ),
            FilterList(
                name: "Bulgarian Adblock list",
                url: URL(string: "https://stanev.org/abp/adblock_bg.txt")!,
                category: .regional
            ),
            FilterList(
                name: "EasyPrivacy",
                url: URL(
                    string:
                        "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/118_optimized.txt"
                )!,
                category: .privacy,
                isSelected: true
            ),
            FilterList(
                name: "Online Malicious URL Blocklist",
                url: URL(
                    string:
                        "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/208_optimized.txt"
                )!,
                category: .security,
                isSelected: true
            ),
            FilterList(
                name: "Peter Lowe's Blocklist",
                url: URL(
                    string:
                        "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/204_optimized.txt"
                )!,
                category: .multipurpose,
                isSelected: true
            ),
            FilterList(
                name: "Hagezi Pro mini",
                url: URL(
                    string:
                        "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.mini.txt"
                )!,
                category: .multipurpose,
                isSelected: true
            ),
            FilterList(
                name: "d3Host List by d3ward",
                url: URL(
                    string:
                        "https://raw.githubusercontent.com/d3ward/toolz/master/src/d3host.adblock"
                )!,
                category: .multipurpose,
                isSelected: true
            ),
            FilterList(
                name: "Anti-Adblock List",
                url: URL(
                    string:
                        "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/207_optimized.txt"
                )!,
                category: .multipurpose,
                isSelected: true
            ),
            FilterList(
                name: "AdGuard Experimental filter",
                url: URL(
                    string:
                        "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/5_optimized.txt"
                )!,
                category: .experimental
            ),
        ]
    }
}
