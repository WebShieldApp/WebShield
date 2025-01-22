//import Foundation
//import SwiftData
//
//// MARK: - Schema Version 1
//@MainActor
//enum SchemaV1: @preconcurrency VersionedSchema {
//    static let versionIdentifier: Schema.Version = Schema.Version(1, 0, 0)
//    static let models: [any PersistentModel.Type] = [
//        FilterList.self
//    ]
//
//    @Model
//    final class FilterList {
//        @Attribute(.unique) var id: String
//        var name: String
//        var isEnabled: Bool
//
//        init(id: String, name: String, isEnabled: Bool) {
//            self.id = id
//            self.name = name
//            self.isEnabled = isEnabled
//        }
//    }
//}
//
//// MARK: - Schema Version 2
//@MainActor
//enum SchemaV2: @preconcurrency VersionedSchema {
//    static let versionIdentifier: Schema.Version = Schema.Version(2, 0, 0)
//    static let models: [any PersistentModel.Type] = [
//        FilterList.self
//    ]
//
//    @Model
//    final class FilterList {
//        @Attribute(.unique) var id: String
//        var name: String
//        var isEnabled: Bool
//        var lastUpdated: Date
//        @Relationship var category: FilterCategory?
//
//        init(id: String, name: String, isEnabled: Bool, lastUpdated: Date = .now) {
//            self.id = id
//            self.name = name
//            self.isEnabled = isEnabled
//            self.lastUpdated = lastUpdated
//        }
//    }
//
//    @Model
//    final class FilterCategory {
//        @Attribute(.unique) var id: String
//        var name: String
//
//        init(id: String, name: String) {
//            self.id = id
//            self.name = name
//        }
//    }
//}
