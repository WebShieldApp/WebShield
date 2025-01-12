import Foundation

enum FilterListProvider {

    static let filterListData: [FilterListData] = [
        FilterListData(
            id: UUID().uuidString,
            name: "AdGuard – Ads",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/2_optimized.txt",
            category: .ads,
            isSelected: true,
            description:
                "EasyList + AdGuard English filter. This filter is necessary for quality ad blocking.",
            homepageURL:
                "https://github.com/AdguardTeam/AdguardFilters#adguard-filters",
            informationURL:
                "https://adguard.com/kb/general/ad-filtering/adguard-filters/"),
        FilterListData(
            id: UUID().uuidString,
            name: "AdGuard – Mobile Ads",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/11_optimized.txt",
            category: .ads,
            isSelected: false,
            description:
                "Filter for all known mobile ad networks. Useful for mobile devices.",
            homepageURL:
                "https://github.com/AdguardTeam/AdguardFilters#adguard-filters",
            informationURL:
                "https://adguard.com/kb/general/ad-filtering/adguard-filters/"
        ),
        FilterListData(
            id: UUID().uuidString,
            name: "EasyList",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/101_optimized.txt",
            category: .ads,
            isSelected: false,
            description:
                "EasyList is the primary subscription that removes adverts from web pages in English. Already included in AdGuard Base filter.",
            homepageURL: "https://easylist.to/"),
        FilterListData(
            id: UUID().uuidString,
            name: "AdGuard Tracking Protection",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/3_optimized.txt",
            category: .privacy,
            isSelected: true,
            description:
                "The most comprehensive list of various online counters and web analytics tools. Use this filter if you do not want your actions on the Internet to be tracked.",
            homepageURL:
                "https://github.com/AdguardTeam/AdguardFilters#adguard-filters",
            informationURL:
                "https://adguard.com/kb/general/ad-filtering/adguard-filters/"),
        FilterListData(
            id: UUID().uuidString,
            name: "EasyPrivacy",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/118_optimized.txt",
            category: .privacy,
            isSelected: true,
            description:
                "Privacy protection supplement for EasyList.",
            homepageURL: "https://easylist.to/"),
        FilterListData(
            id: UUID().uuidString,
            name: "Online Malicious URL Blocklist",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/208_optimized.txt",
            category: .security,
            isSelected: false,
            description:
                "Blocks domains that are known to be used to propagate malware and spyware.",
            homepageURL:
                "https://gitlab.com/malware-filter/urlhaus-filter#malicious-url-blocklist"),
        FilterListData(
            id: UUID().uuidString,
            name: "Phishing URL Blocklist",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/255_optimized.txt",
            category: .security,
            isSelected: false,
            description:
                "Phishing URL blocklist for uBlock Origin (uBO), AdGuard, Vivaldi, Pi-hole, Hosts file, Dnsmasq, BIND, Unbound, Snort and Suricata.",
            homepageURL:
                "https://gitlab.com/malware-filter/phishing-filter#phishing-url-blocklist"),
        FilterListData(
            id: UUID().uuidString,
            name: "Peter Lowe’s Ad and tracking server list",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/204_optimized.txt",
            category: .multipurpose,
            isSelected: false,
            description:
                "Filter that blocks ads, trackers, and other nasty things.",
            homepageURL: "https://pgl.yoyo.org/adservers/"),
        FilterListData(
            id: UUID().uuidString,
            name: "AdGuard – Cookie Notices",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/18_optimized.txt",
            category: .cookies,
            isSelected: false,
            description:
                "Blocks cookie notices on web pages.",
            homepageURL:
                "https://github.com/AdguardTeam/AdguardFilters#adguard-filters",
            informationURL:
                "https://adguard.com/kb/general/ad-filtering/adguard-filters/"),
        FilterListData(
            id: UUID().uuidString,
            name: "EasyList – Cookie Notices",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/241_optimized.txt",
            category: .cookies,
            isSelected: false,
            description:
                "Removes cookie and privacy warnings. Already included in Fanboy's Annoyances list.",
            homepageURL: "https://github.com/easylist/easylist#fanboy-lists"
        ),
        FilterListData(
            id: UUID().uuidString,
            name: "AdGuard – Social Widgets",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/4_optimized.txt",
            category: .social,
            isSelected: false,
            description:
                "Filter for social media widgets such as 'Like' and 'Share' buttons and more.",
            homepageURL:
                "https://github.com/AdguardTeam/AdguardFilters#adguard-filters",
            informationURL:
                "https://adguard.com/kb/general/ad-filtering/adguard-filters/"
        ),
        FilterListData(
            id: UUID().uuidString,
            name: "Fanboy – Social Blocking",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/123_optimized.txt",
            category: .social,
            isSelected: false,
            description:
                "Hides and blocks social content, social widgets, social scripts and social icons. Already included in Fanboy's Annoyances list.",
            homepageURL: "https://github.com/ryanbr/fanboy-adblock/issues"),
        FilterListData(
            id: UUID().uuidString,
            name: "Fanboy – Anti-Facebook",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/225_optimized.txt",
            category: .social,
            isSelected: false,
            description:
                "Warning, it will break Facebook-based comments on some websites and may also break some Facebook apps or games.",
            homepageURL: "https://github.com/ryanbr/fanboy-adblock/issues"
        ),
        FilterListData(
            id: UUID().uuidString,
            name: "AdGuard – Annoyances",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/14_optimized.txt",
            category: .annoyances,
            isSelected: false,
            description:
                "Blocks irritating elements on web pages including cookie notices, third-party widgets and in-page pop-ups. Contains the following AdGuard filters: Cookie Notices, Popups, Mobile App Banners, Other Annoyances and Widgets.",
            homepageURL:
                "https://github.com/AdguardTeam/AdguardFilters#adguard-filters",
            informationURL:
                "https://adguard.com/kb/general/ad-filtering/adguard-filters/"
        ),
        FilterListData(
            id: UUID().uuidString,
            name: "AdGuard – Popup Overlays",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/19_optimized.txt",
            category: .annoyances,
            isSelected: false,
            description:
                "Blocks all kinds of pop-ups that are not necessary for websites' operation according to our Filter policy.",
            homepageURL:
                "https://github.com/AdguardTeam/AdguardFilters#adguard-filters",
            informationURL:
                "https://adguard.com/kb/general/ad-filtering/adguard-filters/"
        ),
        FilterListData(
            id: UUID().uuidString,
            name: "AdGuard – Mobile App Banners",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/20_optimized.txt",
            category: .annoyances,
            isSelected: false,
            description:
                "Blocks all kinds of pop-ups that are not necessary for websites' operation according to our Filter policy.",
            homepageURL:
                "https://github.com/AdguardTeam/AdguardFilters#adguard-filters",
            informationURL:
                "https://adguard.com/kb/general/ad-filtering/adguard-filters/"),
        FilterListData(
            id: UUID().uuidString,
            name: "AdGuard – Other Annoyances",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/21_optimized.txt",
            category: .annoyances,
            isSelected: false,
            description:
                "Blocks irritating elements on web pages that do not fall under the popular categories of annoyances.",
            homepageURL:
                "https://github.com/AdguardTeam/AdguardFilters#adguard-filters",
            informationURL:
                "https://adguard.com/kb/general/ad-filtering/adguard-filters/"
        ),
        FilterListData(
            id: UUID().uuidString,
            name: "AdGuard – Widgets",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/22_optimized.txt",
            category: .annoyances,
            isSelected: false,
            description:
                "Blocks annoying third-party widgets: online assistants, live support chats, etc.",
            homepageURL:
                "https://github.com/AdguardTeam/AdguardFilters#adguard-filters",
            informationURL:
                "https://adguard.com/kb/general/ad-filtering/adguard-filters/"),
        FilterListData(
            id: UUID().uuidString,
            name: "Fanboy – Annoyances",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/122_optimized.txt",
            category: .annoyances,
            isSelected: false,
            description:
                "Removes in-page pop-ups and other annoyances. Includes Fanboy's Social Blocking & EasyList Cookie Lists.",
            homepageURL: "https://github.com/ryanbr/fanboy-adblock/issues"),
        FilterListData(
            id: UUID().uuidString,
            name: "🇷🇺 ru",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/1_optimized.txt",
            category: .regional,
            isSelected: false,
            description:
                "Filter that enables ad blocking on websites in Russian language.",
            homepageURL:
                "https://adguard.com/kb/general/ad-filtering/adguard-filters/"
        ),
        FilterListData(
            id: UUID().uuidString, name: "🇩🇪 de",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/6_optimized.txt",
            category: .regional,
            isSelected: false,
            description:
                "EasyList Germany + AdGuard German filter. Filter list that specifically removes ads on websites in German language.",
            homepageURL:
                "https://adguard.com/kb/general/ad-filtering/adguard-filters/"),
        FilterListData(
            id: UUID().uuidString, name: "🇯🇵 jp",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/7_optimized.txt",
            category: .regional,
            isSelected: false,
            description:
                "Filter that enables ad blocking on websites in Japanese language.",
            homepageURL:
                "https://adguard.com/kb/general/ad-filtering/adguard-filters/"),
        FilterListData(
            id: UUID().uuidString, name: "🇳🇱 nl",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/7_optimized.txt",
            category: .regional,
            isSelected: false,
            description:
                "Filter that enables ad blocking on websites in Japanese language.",
            homepageURL:
                "https://adguard.com/kb/general/ad-filtering/adguard-filters/"),
        FilterListData(
            id: UUID().uuidString, name: "🇪🇸 🇵🇹 es/pt",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/9_optimized.txt",
            category: .regional,
            isSelected: false,
            description:
                "Filter that enables ad blocking on websites in Japanese language.",
            homepageURL:
                "https://adguard.com/kb/general/ad-filtering/adguard-filters/"),
        FilterListData(
            id: UUID().uuidString, name: "🇹🇷 tr",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/13_optimized.txt",
            category: .regional,
            isSelected: false,
            description:
                "Filter list that specifically removes ads on websites in Turkish language.",
            homepageURL:
                "https://adguard.com/kb/general/ad-filtering/adguard-filters/"),
        FilterListData(
            id: UUID().uuidString, name: "🇫🇷 fr",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/16_optimized.txt",
            category: .regional,
            isSelected: false,
            description:
                "Liste FR + AdGuard French filter. Filter list that specifically removes ads on websites in French language.",
            homepageURL:
                "https://adguard.com/kb/general/ad-filtering/adguard-filters/"),
        FilterListData(
            id: UUID().uuidString,
            name: "AdGuard – Experimental",
            urlString:
                "https://filters.adtidy.org/extension/safari/filters/5_optimized.txt",
            category: .experimental,
            isSelected: false,
            description:
                "Filter designed to test certain hazardous filtering rules before they are added to the basic filters.",
            homepageURL:
                "https://github.com/AdguardTeam/AdguardFilters#adguard-filters"
        ),
    ]

    static func filterListDataById(_ id: String) -> FilterListData? {
        return filterListData.first(where: { $0.id == id })
    }
}
