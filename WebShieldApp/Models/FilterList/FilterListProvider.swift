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
                name: "AdGuard – Ads",
                url: URL(
                    string:
                        "https://filters.adtidy.org/extension/safari/filters/2_optimized.txt"
                )!,
                category: .ads,
                isSelected: true
            ),
            FilterList(
                name: "AdGuard – Mobile Ads",
                url: URL(
                    string:
                        "https://filters.adtidy.org/extension/safari/filters/11_optimized.txt"
                )!,
                category: .ads,
                isSelected: false
            ),
            FilterList(
                name: "EasyList",
                url: URL(
                    string:
                        "https://filters.adtidy.org/extension/safari/filters/101_optimized.txt"
                )!,
                category: .ads,
                isSelected: false
            ),
            FilterList(
                name: "AdGuard Tracking Protection",
                url: URL(
                    string:
                        "https://filters.adtidy.org/extension/safari/filters/3_optimized.txt"
                )!,
                category: .privacy,
                isSelected: true
            ),
            FilterList(
                name: "EasyPrivacy",
                url: URL(
                    string:
                        "https://filters.adtidy.org/extension/safari/filters/118_optimized.txt"
                )!,
                category: .privacy,
                isSelected: true
            ),
            FilterList(
                name: "Online Malicious URL Blocklist",
                url: URL(
                    string:
                        "https://filters.adtidy.org/extension/safari/filters/208_optimized.txt"
                )!,
                category: .security,
                isSelected: false
            ),
            FilterList(
                name: "Phishing URL Blocklist",
                url: URL(
                    string:
                        "https://filters.adtidy.org/extension/safari/filters/255_optimized.txt"
                )!,
                category: .security,
                isSelected: false
            ),
            FilterList(
                name: "Hagezi Pro mini",
                url: URL(
                    string:
                        "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.mini.txt"
                )!,
                category: .multipurpose,
                isSelected: false
            ),
            FilterList(
                name: "Peter Lowe's Blocklist",
                url: URL(
                    string:
                        "https://filters.adtidy.org/extension/safari/filters/204_optimized.txt"
                )!,
                category: .multipurpose,
                isSelected: false
            ),
            FilterList(
                name: "d3Host List by d3ward",
                url: URL(
                    string:
                        "https://raw.githubusercontent.com/d3ward/toolz/master/src/d3host.adblock"
                )!,
                category: .multipurpose,
                isSelected: false
            ),
            FilterList(
                name: "AdGuard – Cookie Notices",
                url: URL(
                    string:
                        "https://filters.adtidy.org/extension/safari/filters/18_optimized.txt"
                )!,
                category: .cookies
            ),
            FilterList(
                name: "EasyList – Cookie Notices",
                url: URL(
                    string:
                        "https://filters.adtidy.org/extension/safari/filters/18_optimized.txt"
                )!,
                category: .cookies
            ),
            FilterList(
                name: "AdGuard – Social Widgets",
                url: URL(
                    string:
                        "https://filters.adtidy.org/extension/safari/filters/4_optimized.txt"
                )!,
                category: .social
            ),
            FilterList(
                name: "Fanboy – Anti-Facebook",
                url: URL(
                    string:
                        "https://filters.adtidy.org/extension/safari/filters/225_optimized.txt"
                )!,
                category: .social
            ),
            FilterList(
                name: "AdGuard – Annoyances",
                url: URL(
                    string:
                        "https://filters.adtidy.org/extension/safari/filters/14_optimized.txt"
                )!,
                category: .annoyances
            ),
            FilterList(
                name: "Fanboy's Annoyances filter",
                url: URL(
                    string:
                        "https://filters.adtidy.org/extension/safari/filters/122_optimized.txt"
                )!,
                category: .annoyances
            ),
            FilterList(
                name: "AdGuard Russian filter",
                url: URL(
                    string:
                        "https://filters.adtidy.org/extension/safari/filters/1_optimized.txt"
                )!,
                category: .regional
            ),
            FilterList(
                name: "AdGuard German filter",
                url: URL(
                    string:
                        "https://filters.adtidy.org/extension/safari/filters/6_optimized.txt"
                )!,
                category: .regional
            ),
            FilterList(
                name: "Anti-Adblock",
                url: URL(
                    string:
                        "https://filters.adtidy.org/extension/safari/filters/207_optimized.txt"
                )!,
                category: .multipurpose,
                isSelected: true
            ),
            FilterList(
                name: "AdGuard – Experimental",
                url: URL(
                    string:
                        "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/5_optimized.txt"
                )!,
                category: .experimental
            ),
        ]
    }
}
