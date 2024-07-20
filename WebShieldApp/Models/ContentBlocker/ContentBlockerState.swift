import Foundation
@preconcurrency import SafariServices

@MainActor class ContentBlockerState: ObservableObject {
    private let identifier = "me.arjuna.WebShield.ContentBlocker"
//    @Published private(set) var isEnabled: Bool = true

    init() {
        Task {
            await refreshContentBlockerState()
        }
    }

    func refreshContentBlockerState() async {
        do {
            let state = try await SFContentBlockerManager.stateOfContentBlocker(
                withIdentifier: identifier)
//            self.isEnabled = state.isEnabled
        } catch {
            print(
                "Error fetching content blocker state: \(error.localizedDescription)"
            )
        }
    }

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
                "SFErrorDomain error 1: A Content Blocker or Safari app extension with the specified bundle identifier was not found, or the bundle identifier specified an extension that was not owned by you."
            )
            print("Bundle Identifier: \(self.identifier)")
            print(
                "Please check that the JSON is valid and follows Safari's content blocker format."
            )
            print(
                "Ensure that the file size is under 2MB and contains no more than 50,000 rules."
            )
        case 2:
            print(
                "SFErrorDomain error 2: The Content Blocker extension returned an NSExtensionItem that did not include an attachment."
            )
        case 3:
            print(
                "SFErrorDomain error 3: There was an error loading the content blocker extension."
            )
        default:
            print("Unknown SFErrorDomain error code: \(code)")
        }
    }
}
