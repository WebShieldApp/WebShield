// WebShieldExtra/SafariExtensionViewController.swift
//
//  SafariExtensionViewController.swift
//  Test
//
//  Created by Arjun on 2024-07-13.
//

import SafariServices

class SafariExtensionViewController: SFSafariExtensionViewController {

    let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        shared.preferredContentSize = NSSize(width: 320, height: 240)
        return shared
    }()

}
