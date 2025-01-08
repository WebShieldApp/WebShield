import SafariServices
import SwiftUI

actor ContentBlockerState: ObservableObject {
    private let identifier = "dev.arjuna.WebShield.Filters"

    func reloadContentBlocker() async {
        do {
            try await SFContentBlockerManager.reloadContentBlocker(
                withIdentifier: identifier)
            await LogsView.addLog("Content blocker reloaded successfully")
        } catch {
            await handleReloadError(error)
        }
    }

    private func handleReloadError(_ error: Error) async {
        let nsError = error as NSError
        await LogsView.addLog("ERROR: Failed to reload content blocker")
        await LogsView.addLog("Error description: \(nsError.localizedDescription)")
        await LogsView.addLog("Error domain: \(nsError.domain)")
        await LogsView.addLog("Error code: \(nsError.code)")

        if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey]
            as? NSError
        {
            await LogsView.addLog("Underlying error: \(underlyingError)")
        }

        await LogsView.addLog("User Info:")
        for (key, value) in nsError.userInfo {
            await LogsView.addLog("  \(key): \(value)")
        }

        if nsError.domain == "SFErrorDomain" {
            await handleSFErrorDomain(code: nsError.code)
        }
    }

    private func handleSFErrorDomain(code: Int) async {
        switch code {
        case 1:
            await LogsView.addLog(
                "SFErrorDomain error 1: Content Blocker not found or not owned by you."
            )
            await LogsView.addLog("Bundle Identifier: \(self.identifier)")
            await LogsView.addLog(
                "Please check JSON validity and file size (max 6MB, 150,000 rules)."
            )
        case 2:
            await LogsView.addLog("SFErrorDomain error 2: NSExtensionItem missing attachment.")
        case 3:
            await LogsView.addLog(
                "SFErrorDomain error 3: Error loading content blocker extension."
            )
        default:
            await LogsView.addLog("Unknown SFErrorDomain error code: \(code)")
        }
    }
}
