//import Foundation
//@preconcurrency import SwiftData
//
//struct AppMigrationPlan: SchemaMigrationPlan {
//    static let schemas: [VersionedSchema.Type] = [
//        SchemaVersions.V1.self,
//        SchemaVersions.V2.self,
//    ]
//
//    static var stages: [MigrationStage] {
//        [migrateV1toV2]
//    }
//
//    static let migrateV1toV2 = MigrationStage.custom(
//        fromVersion: SchemaVersions.V1.self,
//        toVersion: SchemaVersions.V2.self,
//        willMigrate: { context in
//            let oldLists = try context.fetch(FetchDescriptor<SchemaVersions.V1.FilterList>())
//
//            for oldList in oldLists {
//                let newList = SchemaVersions.V2.FilterList(
//                    id: oldList.id,
//                    name: oldList.name,
//                    isEnabled: oldList.isEnabled,
//                    lastUpdated: Date.now  // Default value
//                )
//                context.insert(newList)
//            }
//
//            try context.save()
//        },
//        didMigrate: { context in
//            // Optional post-migration cleanup
//        }
//    )
//}
