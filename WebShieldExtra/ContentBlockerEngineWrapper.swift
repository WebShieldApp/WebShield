//
//  ContentBlockerEngineWrapper.swift
//  WebShieldScripts
//
//  Created by Arjun on 2024-07-13.
//

import ContentBlockerEngine
import Foundation

class ContentBlockerEngineWrapper {
    private var contentBlockerEngine: ContentBlockerEngine
    @MainActor static let shared = ContentBlockerEngineWrapper()
    init() {
        let requiredPart: String = "G5S45S77DF.me.arjuna.WebShield"
        let advancedBlockingURL: URL? = FileManager.default
            .containerURL(
                forSecurityApplicationGroupIdentifier: requiredPart)!.appending(
                path: "advancedBlocking.json",
                directoryHint: URL.DirectoryHint.notDirectory
            )
        let json: String = try! String(
            contentsOf: advancedBlockingURL!,
            encoding: .utf8
        )
        self.contentBlockerEngine = try! ContentBlockerEngine(json)
    }

    public func getData(url: URL) -> String {
        return try! self.contentBlockerEngine.getData(url: url)
    }
}
