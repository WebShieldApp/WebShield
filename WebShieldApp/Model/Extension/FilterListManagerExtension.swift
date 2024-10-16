//
//  FilterListManagerExtension.swift
//  WebShield
//
//  Created by Arjun on 2024-10-11.
//

import Foundation

extension FilterListManager {
    func parseMetadata(from content: String) -> (
        title: String?, description: String?, version: String?
    ) {
        var title: String?
        var description: String?
        var version: String?

        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            if line.hasPrefix("! Title:") {
                title = line.replacingOccurrences(of: "! Title:", with: "")
                    .trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("! Description:") {
                description = line.replacingOccurrences(
                    of: "! Description:", with: ""
                ).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("! Version:") {
                version = line.replacingOccurrences(of: "! Version:", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }

            if title != nil && description != nil && version != nil {
                break
            }
        }

        return (title, description, version)
    }

    func downloadFilterList(from url: URL, name: String) async throws -> (
        Data, String
    ) {
        Logger.logMessage(
            "Downloading Filter List: \(name) from URL: \(url.absoluteString)")
        let (data, _) = try await urlSession.data(from: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw FilterListError.invalidData
        }
        return (data, content)
    }
}
