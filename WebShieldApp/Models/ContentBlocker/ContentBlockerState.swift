import Foundation
@preconcurrency import SafariServices

@MainActor class ContentBlockerState: ObservableObject {
    let identifier: String

    @Published private var state: Result<Bool, Error>?

    var isEnabled: Bool {
        guard case .success(let isEnabled) = state else { return false }
        return isEnabled
    }

    init() {
        self.identifier = "me.arjuna.WebShield.ContentBlocker"
    }

    func refreshContentBlockerState() async {
        do {
            let state = try await SFContentBlockerManager.stateOfContentBlocker(
                withIdentifier: identifier)
            self.state = .success(state.isEnabled)
        } catch {
            self.state = .failure(error)
        }
    }

    func toggleContentBlocker() async {
        do {
            let newState =
                try await SFContentBlockerManager.stateOfContentBlocker(
                    withIdentifier: identifier)

            switch self.state {
            case .success(let isEnabled):
                // Toggle the current state
                self.state = .success(!isEnabled)
                
                // If the new state doesn't match our toggle, log a warning
                if newState.isEnabled == isEnabled {
                    print(
                        "Warning: Content blocker state didn't change as expected"
                    )
                }

            case .failure, nil:
                // If we had a failure or nil state before, use the new state
                self.state = .success(newState.isEnabled)
                print(
                    "Content blocker state updated from previous failure or nil state"
                )

            }

            // Attempt to reload the content blocker
            await reloadContentBlocker()

        } catch {
            self.state = .failure(error)
            print(
                "Error toggling content blocker: \(error.localizedDescription)")
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
