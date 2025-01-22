enum RefreshState {
    case idle
    case refreshing
    case success
    case failed([RefreshError])  // Store the errors if it failed
}
