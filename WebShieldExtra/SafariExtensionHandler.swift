//
//  SafariExtensionHandler.swift
//  Test
//
//  Created by Arjun on 2024-07-13.
//

import ContentBlockerEngine
import SafariServices
import os.log

class SafariExtensionHandler: SFSafariExtensionHandler {
    let logger = Logger()
    override func beginRequest(with context: NSExtensionContext) {
        guard let request = context.inputItems.first as? NSExtensionItem,
            request.userInfo as? [String: Any] != nil
        else {
            return
        }
        let profile: UUID?
        if #available(iOS 17.0, macOS 14.0, *) {
            profile = request.userInfo?[SFExtensionProfileKey] as? UUID
        } else {
            profile = request.userInfo?["profile"] as? UUID
        }
        self.logger.log(
            level: .default,
            "The extension received a request for profile: \(profile!.uuidString, privacy: .public)"
        )
    }

    @MainActor override func messageReceived(
        withName messageName: String, from page: SFSafariPage,
        userInfo: [String: Any]?
    ) {
        page.getPropertiesWithCompletionHandler { properties in
            self.logger.log(
                level: .default,
                "The extension received a message \(messageName, privacy: .public) from a script injected into \(String(describing: properties?.url), privacy: .public) with userInfo \(userInfo!, privacy: .public)"
            )
        }
        // Content script requests scripts and css for current page
        if messageName == "getAdvancedBlockingData" {
            if userInfo == nil || userInfo!["url"] == nil {
                self.logger.log(
                    level: .default, "Empty url passed with the message")
                return
            }
            let url = userInfo?["url"] as? String

            let pageUrl = URL(string: url!)!
            let data: [String: Any]? = [
                "url": url!,
                "data": ContentBlockerEngineWrapper.shared.getData(
                    url: pageUrl),
                "verbose": true,
            ]
            page.dispatchMessageToScript(
                withName: "advancedBlockingData", userInfo: data)
        }

    }

    override func toolbarItemClicked(in window: SFSafariWindow) {
        os_log(.default, "The extension's toolbar item was clicked")
    }

    override func validateToolbarItem(
        in window: SFSafariWindow,
        validationHandler: @escaping ((Bool, String) -> Void)
    ) {
        validationHandler(true, "")
    }

    @MainActor override func popoverViewController()
        -> SFSafariExtensionViewController
    {
        return SafariExtensionViewController.shared
    }

}
