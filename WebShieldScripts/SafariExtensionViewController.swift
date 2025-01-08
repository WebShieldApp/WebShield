import SafariServices
import os.log

final class SafariExtensionViewController: SFSafariExtensionViewController {

    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        shared.preferredContentSize = NSSize(width: 240, height: 150)
        return shared
    }()
}
