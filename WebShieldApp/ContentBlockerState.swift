//
//  ContentBlockerState.swift
//  WebShieldApp
//
//  Created by Arjun on 25/6/24.
//

import SafariServices
import SwiftUI

class ContentBlockerState: ObservableObject {

    init(withIdentifier identifier: String) {
        self.identifier = identifier
//        refreshContentBlockerState()
    }

    let identifier: String

    @Published var state: Result<Bool, Error>? = nil

    var isEnabled: Bool {
        switch state {
        case .success(let isEnabled):
            return isEnabled
        case .failure,
            nil:
            return false
        }
    }

    func refreshContentBlockerState() {
        SFContentBlockerManager
            .getStateOfContentBlocker(
                withIdentifier: self.identifier
            ) {
                state, error in

                if let state = state {
                    self.state = .success(state.isEnabled)
                } else if let error = error {
                    self.state = .failure(error)
                } else {
                    self.state = nil
                }
            }
    }

    func reloadContentBlocker() {
        SFContentBlockerManager
            .reloadContentBlocker(
                withIdentifier: self.identifier
            ) { error in
                if let error = error as NSError? {
                    print("ERROR: Failed to reload content blocker")
                    print(
                        "Error description: \(error.localizedDescription)")
                    print("Error domain: \(error.domain)")
                    print("Error code: \(error.code)")
                    if let underlyingError = error.userInfo[
                        NSUnderlyingErrorKey] as? NSError
                    {
                        print("Underlying error: \(underlyingError)")
                    }
                    print("User Info:")
                    for (key, value) in error.userInfo {
                        print("  \(key): \(value)")
                    }
                    // Additional debugging for SFErrorDomain error 1
                    if error.domain == "SFErrorDomain" {
                        if error.code == 1 {
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
                        }
                        if error.code == 2 {
                            print(
                                "SFErrorDomain error 2: The Content Blocker extension returned an NSExtensionItem that did not include an attachment."
                            )
                        }
                        if error.code == 3 {
                            print(
                                "SFErrorDomain error 3: There was an error loading the content blocker extension."
                            )
                        }
                    }
                } else {
                    print("Content blocker reloaded successfully")
                }
            }
    }
}
