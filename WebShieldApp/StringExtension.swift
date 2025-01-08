// Helper extension for String truncation
extension String {
    func truncated(to length: Int, trailing: String = "...") -> String {
        return self.count > length
            ? String(self.prefix(length)) + trailing : self
    }
}
