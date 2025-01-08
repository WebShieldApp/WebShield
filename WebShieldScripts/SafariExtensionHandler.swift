import ContentBlockerEngine
import SafariServices
import os

final class SafariExtensionHandler: SFSafariExtensionHandler {
    private let logger = Logger(
        subsystem: "dev.arjuna.WebShield.Scripts",
        category: "SafariExtensionHandler")
    override func messageReceived(
        withName messageName: String, from page: SFSafariPage,
        userInfo: [String: Any]?
    ) {
        page.getPropertiesWithCompletionHandler { properties in
            self.logger.info(
                "The extension received a message (\(messageName, privacy: .public)) from a script injected into (\(String(describing: properties?.url), privacy: .public)) with userInfo (\(userInfo ?? [:], privacy: .public))"
            )
        }

        if messageName == "getAdvancedBlockingData" {
            guard let userInfo = userInfo,
                  let urlString = userInfo["url"] as? String,
                  let pageUrl = URL(string: urlString)
            else {
                logger.info("Invalid message or URL")
                return
            }

                // Test method call to trigger further initialization
            if let mainData = ContentBlockerEngineWrapper.shared.getData(
                url: pageUrl)
            {
            let data: [String: Any] = [
                "url": urlString,
                "data": mainData,
                "verbose": true,
            ]
            logger.info("Data received: (\(mainData, privacy: .public))")

            page.dispatchMessageToScript(
                withName: "advancedBlockingData", userInfo: data)
            } else {
                logger.error(
                    "Failed to get data for URL: \(pageUrl.absoluteString, privacy: .public)"
                )
            }
        }
    }

    override func toolbarItemClicked(in window: SFSafariWindow) {
        logger.log(level: .default, "The extension's toolbar item was clicked")
    }

    override func validateToolbarItem(
        in window: SFSafariWindow,
        validationHandler: @escaping ((Bool, String) -> Void)
    ) {
        validationHandler(true, "")
    }

        //    override func popoverViewController() -> SFSafariExtensionViewController {
        //        SafariExtensionViewController.shared
        //    }
}
