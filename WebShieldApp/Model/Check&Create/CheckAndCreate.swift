//
//  CheckAndCreate.swift
//  WebShieldApp
//
//  Created by Arjun on 2024-09-08.
//

import Foundation

@MainActor
struct CheckAndCreate {
    static func checkAndCreateGroupFolder() {
        guard let containerURL = GroupContainerURL.groupContainerURL() else {
            Logger.logMessage("Error: Unable to access shared container")
            return
        }

        if FileManager.default.fileExists(atPath: containerURL.path) {
            Logger.logMessage(
                "Group folder already exists: \(containerURL.path)")
            return
        }

        do {
            try FileManager.default.createDirectory(
                at: containerURL, withIntermediateDirectories: true)
            Logger.logMessage("Created group folder: \(containerURL.path)")
        } catch {
            Logger.logMessage(
                "Error creating group folder: \(error.localizedDescription)")
        }
    }
}
