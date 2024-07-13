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
    override func beginRequest(with context: NSExtensionContext) {
        guard let request = context.inputItems.first as? NSExtensionItem,
            let _ = request.userInfo as? [String: Any]
        else {
            return
        }
        let profile: UUID?
        if #available(iOS 17.0, macOS 14.0, *) {
            profile = request.userInfo?[SFExtensionProfileKey] as? UUID
        } else {
            profile = request.userInfo?["profile"] as? UUID
        }

        os_log(
            .default,
            "The extension received a request for profile: %{public}@",
            profile?.uuidString ?? "none")
    }

    override func messageReceived(
        withName messageName: String, from page: SFSafariPage,
        userInfo: [String: Any]?
    ) {
        page.getPropertiesWithCompletionHandler { properties in
            os_log(
                .default,
                "The extension received a message (%{public}@) from a script injected into (%{public}@) with userInfo (%{public}@)",
                messageName, String(describing: properties?.url),
                userInfo ?? [:])
        }
        // Content script requests scripts and css for current page
        //        os_log(.default, "Message Name: %{public}@", messageName)
        if messageName == "getAdvancedBlockingData" {
            if userInfo == nil || userInfo!["url"] == nil {
                os_log(.default, "Empty url passed with the message")
                return
            }
            //            os_log(.default, "Inside if Statement")
            let url = userInfo?["url"] as? String
            //            os_log(.default, "Page url: %{public}@", url!)

            let pageUrl = URL(string: url!)!
            let data: [String: Any]? = [
                "url": url!,
                "data": ContentBlockerEngineWrapper.shared.getData(url: pageUrl),
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

    override func popoverViewController() -> SFSafariExtensionViewController {
        return SafariExtensionViewController.shared
    }

}
