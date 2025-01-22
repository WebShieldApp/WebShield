import SafariServices
import SwiftUI

actor ContentBlockerState: ObservableObject {
    // Reload content blocker for a specific category
    func reloadContentBlocker(for category: FilterListCategory) async throws {
        // Skip reloading for the "all" category
        guard category != .all else { return }

        let identifier = "dev.arjuna.WebShield.DeclarativeBlockList-\(category.rawValue)"
        do {
            try await SFContentBlockerManager.reloadContentBlocker(withIdentifier: identifier)
            await LogsView.addLog("Content blocker reloaded successfully for category: \(category.rawValue)")
        } catch {
            await handleReloadError(error, for: category)
        }
    }

    // Handle errors, now with category
    private func handleReloadError(_ error: Error, for category: FilterListCategory) async {
        let nsError = error as NSError
        await LogsView.addLog("ERROR: Failed to reload content blocker for category: \(category.rawValue)")
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
            await handleSFErrorDomain(code: nsError.code, for: category)
        }
    }

    // Handle SFErrorDomain errors, now with category
    private func handleSFErrorDomain(code: Int, for category: FilterListCategory) async {
        let identifier = "dev.arjuna.WebShield.DeclarativeBlockList-\(category.rawValue)"
        switch code {
        case 1:
            await LogsView.addLog(
                "SFErrorDomain error 1: Content Blocker not found or not owned by you."
            )
            await LogsView.addLog("Bundle Identifier: \(identifier)")
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
