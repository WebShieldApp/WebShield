//
//  StringExtension.swift
//  WebShield
//
//  Created by Arjun on 12/13/24.
//

// Helper extension for String truncation
extension String {
    func truncated(to length: Int, trailing: String = "...") -> String {
        return self.count > length
            ? String(self.prefix(length)) + trailing : self
    }
}
