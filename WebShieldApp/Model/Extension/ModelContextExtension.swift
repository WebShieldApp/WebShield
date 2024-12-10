//
//  ModelContextExtension.swift
//  WebShield
//
//  Created by Arjun on 2024-11-26.
//

import Foundation
import SwiftData

extension ModelContext {
    func deleteAll<T: PersistentModel>(_ type: T.Type) throws {
        let fetchDescriptor = FetchDescriptor<T>()
        let results = try fetch(fetchDescriptor)
        for object in results {
            delete(object)
        }
    }
}
