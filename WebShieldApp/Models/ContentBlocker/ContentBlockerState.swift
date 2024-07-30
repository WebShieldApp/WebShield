import Foundation
import SafariServices

actor ContentBlockerState: ObservableObject {
    private let identifier = "me.arjuna.WebShield.ContentBlocker"

    func reloadContentBlocker() async {
        do {
            try await SFContentBlockerManager.reloadContentBlocker(
                withIdentifier: identifier)
            print("Content blocker reloaded successfully")
        } catch {
            await handleReloadError(error)
        }
    }

    private func handleReloadError(_ error: Error) async {
        let nsError = error as NSError
        print("ERROR: Failed to reload content blocker")
        print("Error description: \(nsError.localizedDescription)")
        print("Error domain: \(nsError.domain)")
        print("Error code: \(nsError.code)")

        if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey]
            as? NSError
        {
            print("Underlying error: \(underlyingError)")
        }

        print("User Info:")
        for (key, value) in nsError.userInfo {
            print("  \(key): \(value)")
        }

        if nsError.domain == "SFErrorDomain" {
            await handleSFErrorDomain(code: nsError.code)
        }
    }

    private func handleSFErrorDomain(code: Int) async {
        switch code {
        case 1:
            print(
                "SFErrorDomain error 1: Content Blocker not found or not owned by you."
            )
            print("Bundle Identifier: \(self.identifier)")
            print(
                "Please check JSON validity and file size (max 2MB, 50,000 rules)."
            )
        case 2:
            print("SFErrorDomain error 2: NSExtensionItem missing attachment.")
        case 3:
            print(
                "SFErrorDomain error 3: Error loading content blocker extension."
            )
        default:
            print("Unknown SFErrorDomain error code: \(code)")
        }
    }
}
