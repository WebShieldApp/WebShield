//
//  FilterListProvider.swift
//  WebShieldApp
//

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
    static let filterListData: [FilterListData] = [
        FilterListData(
            name: "AdGuard Base filter (Optimized)",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/2_optimized.txt",
            category: .ads,
            isSelected: true,
            description:
                "EasyList + AdGuard English filter. This filter is necessary for quality ad blocking."
        ),
        FilterListData(
            name: "AdGuard Mobile Ads filter (Optimized)",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/11_optimized.txt",
            category: .ads,
            isSelected: false,
            description:
                "Filter for all known mobile ad networks. Useful for mobile devices."
        ),
        FilterListData(
            name: "EasyList (Optimized)",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/101_optimized.txt",
            category: .ads,
            isSelected: false,
            description:
                "EasyList is the primary subscription that removes adverts from web pages in English. Already included in AdGuard Base filter."
        ),
        FilterListData(
            name: "AdGuard Tracking Protection filter (Optimized)",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/3_optimized.txt",
            category: .privacy,
            isSelected: false,
            description:
                "The most comprehensive list of various online counters and web analytics tools. Use this filter if you do not want your actions on the Internet to be tracked."
        ),
        FilterListData(
            name: "EasyPrivacy (Optimized)",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/118_optimized.txt",
            category: .privacy,
            isSelected: false,
            description:
                "Privacy protection supplement for EasyList."
        ),
        FilterListData(
            name: "Online Malicious URL Blocklist (Optimized)",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/208_optimized.txt",
            category: .security,
            isSelected: false,
            description:
                "Blocks domains that are known to be used to propagate malware and spyware."
        ),
        FilterListData(
            name: "Phishing URL Blocklist (Optimized)",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/255_optimized.txt",
            category: .security,
            isSelected: false,
            description:
                "Phishing URL blocklist for uBlock Origin (uBO), AdGuard, Vivaldi, Pi-hole, Hosts file, Dnsmasq, BIND, Unbound, Snort and Suricata."
        ),
        FilterListData(
            name: "Peter Lowe's Blocklist (Optimized)",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/204_optimized.txt",
            category: .multipurpose,
            isSelected: false,
            description:
                "Filter that blocks ads, trackers, and other nasty things."
        ),
        FilterListData(
            name: "AdGuard Cookie Notices filter (Optimized)",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/18_optimized.txt",
            category: .cookies,
            isSelected: false,
            description:
                "Blocks cookie notices on web pages."
        ),
        FilterListData(
            name: "EasyList Cookie List (Optimized)",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/241_optimized.txt",
            category: .cookies,
            isSelected: false,
            description:
                "Removes cookie and privacy warnings. Already included in Fanboy's Annoyances list."
        ),
        FilterListData(
            name: "AdGuard Social Media filter (Optimized)",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/4_optimized.txt",
            category: .social,
            isSelected: false,
            description:
                "Filter for social media widgets such as 'Like' and 'Share' buttons and more."
        ),
        FilterListData(
            name: "Fanboy's Social Blocking List (Optimized)",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/123_optimized.txt",
            category: .social,
            isSelected: false,
            description:
                "Hides and blocks social content, social widgets, social scripts and social icons. Already included in Fanboy's Annoyances list."
        ),
        FilterListData(
            name: "Fanboy's Anti-Facebook List (Optimized)",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/225_optimized.txt",
            category: .social,
            isSelected: false,
            description:
                "Warning, it will break Facebook-based comments on some websites and may also break some Facebook apps or games."
        ),
        FilterListData(
            name: "AdGuard Annoyances filter (Optimized)",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/14_optimized.txt",
            category: .annoyances,
            isSelected: false,
            description:
                "Blocks irritating elements on web pages including cookie notices, third-party widgets and in-page pop-ups. Contains the following AdGuard filters: Cookie Notices, Popups, Mobile App Banners, Other Annoyances and Widgets.",
            isAdGuardAnnoyancesList: true,
            childrenNames: [
                "AdGuard Cookie Notices filter (Optimized)",
                "AdGuard Popups filter (Optimized)",
                "AdGuard Mobile App Banners filter (Optimized)",
                "AdGuard Other Annoyances filter (Optimized)",
                "AdGuard Widgets filter (Optimized)",
            ]
        ),
        FilterListData(
            name: "AdGuard Popups filter (Optimized)",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/19_optimized.txt",
            category: .annoyances,
            isSelected: false,
            description:
                "Blocks all kinds of pop-ups that are not necessary for websites' operation according to our Filter policy."
        ),
        FilterListData(
            name: "AdGuard Mobile App Banners filter (Optimized)",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/20_optimized.txt",
            category: .annoyances,
            isSelected: false,
            description:
                "Blocks all kinds of pop-ups that are not necessary for websites' operation according to our Filter policy."
        ),
        FilterListData(
            name: "AdGuard Other Annoyances filter (Optimized)",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/21_optimized.txt",
            category: .annoyances,
            isSelected: false,
            description:
                "Blocks irritating elements on web pages that do not fall under the popular categories of annoyances."
        ),
        FilterListData(
            name: "AdGuard Widgets filter (Optimized)",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/22_optimized.txt",
            category: .annoyances,
            isSelected: false,
            description:
                "Blocks annoying third-party widgets: online assistants, live support chats, etc."
        ),
        FilterListData(
            name: "Fanboy's Annoyances (Optimized)",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/122_optimized.txt",
            category: .annoyances,
            isSelected: false,
            description:
                "Removes in-page pop-ups and other annoyances. Includes Fanboy's Social Blocking & EasyList Cookie Lists."
        ),
        FilterListData(
            name: "AdGuard Russian filter (Optimized)",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/1_optimized.txt",
            category: .regional,
            isSelected: false,
            description:
                "Filter that enables ad blocking on websites in Russian language."
        ),
        FilterListData(
            name: "AdGuard German filter (Optimized)",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/6_optimized.txt",
            category: .regional,
            isSelected: false,
            description:
                "EasyList Germany + AdGuard German filter. Filter list that specifically removes ads on websites in German language."
        ),
        FilterListData(
            name: "Adblock Warning Removal List (Optimized)",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/207_optimized.txt",
            category: .multipurpose,
            isSelected: false,
            description:
                "Removes anti-adblock warnings and other obtrusive messages."
        ),
        FilterListData(
            name: "AdGuard Experimental filter (Optimized)",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/5_optimized.txt",
            category: .experimental,
            isSelected: false,
            description:
                "Filter designed to test certain hazardous filtering rules before they are added to the basic filters."
        ),
    ]

    static var allFilterLists: [FilterList] {
        []
    }
}

struct FilterListData {
    let name: String
    let urlString: String
    let category: FilterListCategory
    let isSelected: Bool
    let description: String
    let isAdGuardAnnoyancesList: Bool
    let childrenNames: [String]?  // For hierarchy

    init(
        name: String, urlString: String, category: FilterListCategory,
        isSelected: Bool, description: String,
        isAdGuardAnnoyancesList: Bool = false, childrenNames: [String]? = nil
    ) {
        self.name = name
        self.urlString = urlString
        self.category = category
        self.isSelected = isSelected
        self.description = description
        self.isAdGuardAnnoyancesList = isAdGuardAnnoyancesList
        self.childrenNames = childrenNames
    }
}
