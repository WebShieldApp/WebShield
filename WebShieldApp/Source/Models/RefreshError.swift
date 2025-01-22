import Foundation

struct RefreshError: Identifiable, Equatable {  // Equatable to remove duplicates
    let id = UUID()  // Automatic unique identifier
    let title: String
    let message: String
    let timestamp: Date

    // Static method for creating localized error descriptions
    static func localizedError(for error: Error, in listName: String) -> RefreshError {
        let title = "Error in \(listName)"
        let message: String

        switch error {
        case FilterListError.invalidURL:
            message = NSLocalizedString("The provided URL is not valid.", comment: "Invalid URL error")
        case FilterListError.invalidData:
            message = NSLocalizedString("Invalid filter list data.", comment: "Invalid data error")
        case FilterListError.invalidFormat:
            message = NSLocalizedString("Invalid filter list format.", comment: "Invalid format error")
        case FilterListError.downloadFailed:
            message = NSLocalizedString("Failed to download filter list.", comment: "Download failed error")
        case FilterListError.parsingFailed:
            message = NSLocalizedString("Failed to parse filter list.", comment: "Parsing failed error")
        case FilterListError.invalidServerResponse:
            message = NSLocalizedString(
                "Failed to receive filter list due to invalid server response.",
                comment: "Invalid server response error")
        default:
            message = NSLocalizedString("An unexpected error occurred.", comment: "Unexpected error")
        }

        return RefreshError(title: title, message: message, timestamp: Date())
    }

    static func == (lhs: RefreshError, rhs: RefreshError) -> Bool {
        lhs.title == rhs.title && lhs.message == rhs.message
    }

    // Consider adding an initializer from NSError if needed
}
