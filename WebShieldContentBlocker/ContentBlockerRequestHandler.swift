import Foundation

final class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        let requiredPart = "group.dev.arjuna.WebShield"

        guard
            let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: requiredPart)
        else {
            print(
                "Error: Could not get container URL for group \(requiredPart)")
            context.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

        let blockerlistURL = containerURL.appendingPathComponent(
            "blockerList.json")  // Use appendingPathComponent

        guard FileManager.default.fileExists(atPath: blockerlistURL.path) else {
            print("Content Blocker Error: blockerList.json does not exist")
            context.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

            // Use if let instead of force unwrapping
        if let attachment = NSItemProvider(contentsOf: blockerlistURL) {
            let item = NSExtensionItem()
            item.attachments = [attachment]
            context.completeRequest(
                returningItems: [item], completionHandler: nil)
        } else {
            print(
                "Error: Could not create NSItemProvider for \(blockerlistURL)")
            context.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
}
