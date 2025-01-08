import Foundation
import os

private let logger = Logger(subsystem: "dev.arjuna.WebShield.Filters", category: "ContentBlockerRequestHandler")

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        let requiredPart = "group.dev.arjuna.WebShield"

        logger.log("Content Blocker logging...")

        guard
            let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: requiredPart)
        else {
            logger.log(
                "Error: Could not get container URL for group \(requiredPart, privacy: .public)")
            context.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

        logger.log("Successfully got container URL for group \(requiredPart, privacy: .public)")

        let blockerlistURL = containerURL.appendingPathComponent(
            "blockerList.json")

        guard FileManager.default.fileExists(atPath: blockerlistURL.path) else {
            logger.log("Content Blocker Error: blockerList.json does not exist")
            context.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

        logger.log("blockerList.json exists")

        if let attachment = NSItemProvider(contentsOf: blockerlistURL) {
            logger.log("Sending attachment")
            let item = NSExtensionItem()
            item.attachments = [attachment]
            context.completeRequest(
                returningItems: [item], completionHandler: nil)
            logger.log("Completed request")
        } else {
            logger.log(
                "Error: Could not create NSItemProvider for \(blockerlistURL)")
            context.completeRequest(returningItems: nil, completionHandler: nil)
        }

    }
}