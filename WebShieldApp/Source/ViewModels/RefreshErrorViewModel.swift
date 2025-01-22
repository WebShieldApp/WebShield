import SwiftUI

@MainActor
class RefreshErrorViewModel: ObservableObject {
    @Published var errors: [RefreshError] = []
    @Published var showErrorView: Bool = false  // Flag to show/hide the ErrorView

    // Clear errors
    func clearErrors() {
        errors.removeAll()
        showErrorView = false  // Also hide the view when clearing
    }

    // Add an error
    func addError(_ error: RefreshError) {
        if !errors.contains(error) {
            errors.append(error)
        }
    }
}
