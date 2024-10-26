//
//  Logger.swift
//  WebShieldApp
//
//  Created by Arjun on 2024-09-08.
//

import Foundation

@MainActor
class Logger {
    static var logs: String = ""
    static func logMessage(_ message: String) {
        print(message)
        Logger.logs += message + "\n"
        writeLogsToFile()
    }

    private static func writeLogsToFile() {
        guard
            let containerURL = GroupContainerURL.groupContainerURL()
        else { return }
        let fileURL = containerURL.appendingPathComponent("logs.txt")

        do {
            try Logger.logs.write(
                to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            Logger.logMessage("Error saving logs: \(error)")
        }
    }

    func readLogsFromFile() {
        guard
            let containerURL = GroupContainerURL.groupContainerURL()
        else { return }
        let fileURL = containerURL.appendingPathComponent("logs.txt")
        do {
            Logger.logs = try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            Logger.logMessage("Error loading logs: \(error)")
        }
    }

    static func clearLogs() {
        Logger.logs = ""
        Logger.writeLogsToFile()
    }

}
