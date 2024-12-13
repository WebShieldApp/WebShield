// Logger.swift

import Foundation

@MainActor
class WSLogger {
    static var logs: [String] = []

    static func log(_ message: String) {
        logs.append(message)
    }
}
