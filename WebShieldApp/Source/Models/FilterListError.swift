import Foundation

enum FilterListError: LocalizedError {
    case invalidData
    case invalidFormat
    case downloadFailed
    case parsingFailed
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The provided URL is not valid."
        case .invalidData:
            return "Invalid filter list data"
        case .invalidFormat:
            return "Invalid filter list format"
        case .downloadFailed:
            return "Failed to download filter list"
        case .parsingFailed:
            return "Failed to parse filter list"
        }
    }
}
