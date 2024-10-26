//
//  FilterListProcessor.swift
//  WebShield
//
//  Created by Arjun on 2024-10-19.
//

import ContentBlockerConverter
import Foundation

struct FilterListProcessor {
    let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func downloadFilterList(from url: URL, name: String) async throws -> Data {
        let (data, _) = try await urlSession.data(from: url)
        return data
    }

    func parseRules(_ data: Data) throws -> [String] {
        //        Logger.logMessage("Parsing rules...")
        guard let content = String(data: data, encoding: .utf8) else {
            throw FilterListError.invalidData
        }

        return content.components(separatedBy: .newlines)
            .filter { !$0.hasPrefix("!") && !$0.hasPrefix("[") && !$0.isEmpty }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    func convertToAdGuardFormat(_ rules: [String]) async throws
        -> ConversionResult
    {
        //        Logger.logMessage("Converting to AdGuard format...")
        return ContentBlockerConverter().convertArray(
            rules: rules,
            safariVersion: .safari16_4,
            optimize: true,
            advancedBlocking: true,
            advancedBlockingFormat: .json
        )
    }
}
