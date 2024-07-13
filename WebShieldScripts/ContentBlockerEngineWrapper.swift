//
//  ContentBlockerEngineWrapper.swift
//  WebShieldScripts
//
//  Created by Arjun on 2024-07-13.
//

import ContentBlockerEngine
import Foundation
import os.log

class ContentBlockerEngineWrapper {
    private var contentBlockerEngine: ContentBlockerEngine
    static let shared = ContentBlockerEngineWrapper()
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
        //        os_log("Contents: %{public}@", contents!)
        self.contentBlockerEngine = try! ContentBlockerEngine(json)
    }

    public func getData(url: URL) -> String {
        let dat = try! self.contentBlockerEngine.getData(url: url)
//        os_log(.default, "URL (getData): %{public}@", url.absoluteString)
        os_log(
            .default,
            "Data (getData): %{public}@", dat)
        return dat
    }
}
