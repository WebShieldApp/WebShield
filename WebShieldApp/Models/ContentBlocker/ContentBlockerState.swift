import Foundation
@preconcurrency import SafariServices

@MainActor class ContentBlockerState: ObservableObject {
    let identifier: String

    @Published private(set) var state: Result<Bool, Error>?

    var isEnabled: Bool {
        guard case .success(let isEnabled) = state else { return false }
        return isEnabled
    }

    init(withIdentifier identifier: String) {
        self.identifier = identifier
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
