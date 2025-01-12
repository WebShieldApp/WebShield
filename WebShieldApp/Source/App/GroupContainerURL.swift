import Foundation

@MainActor
struct GroupContainerURL {
    private static let fileManager: FileManager = FileManager.default
    static func groupContainerURL() -> URL? {
        return fileManager.containerURL(
            forSecurityApplicationGroupIdentifier:
                Identifiers.groupID)
    }
}
