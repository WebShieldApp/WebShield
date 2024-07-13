import Foundation

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        let requiredPart = "G5S45S77DF.me.arjuna.WebShield"
        let blockerlistURL = FileManager.default
            .containerURL(
                forSecurityApplicationGroupIdentifier: requiredPart)!.appending(
                path: "blockerList.json",
                directoryHint: URL.DirectoryHint.notDirectory
            )
        guard FileManager.default.fileExists(atPath: blockerlistURL.path)
        else {
            print("Content Blocker Error: blockerList.json does not exist")
            context.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }
        let attachment = NSItemProvider(
            contentsOf: blockerlistURL)!
        let item = NSExtensionItem()
        item.attachments = [attachment]

        context.completeRequest(returningItems: [item], completionHandler: nil)
    }
}
