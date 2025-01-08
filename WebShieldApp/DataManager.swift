import Foundation
import SwiftData

@MainActor
final class DataManager: ObservableObject {
    let container: ModelContainer
    private let filterListProcessor = FilterListProcessor()

    init() {
        // Initialize ModelContainer once
        guard
            let groupURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: Identifiers.groupID)
        else {
            fatalError("Failed to get container URL for app group.")
        }

        let storeURL = groupURL.appendingPathComponent("Library/Application Support/default.store")
        let config = ModelConfiguration(url: storeURL)

        // Define the schema for your models
        let schema = Schema([FilterList.self])

        // Initialize the container with the schema and configuration
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    /// Resets the data model by deleting all records and reseeding.
    func resetModel() {
        let context = ModelContext(container)
        Task {
            do {
                let fetchRequest = FetchDescriptor<FilterList>()
                let results = try context.fetch(fetchRequest)
                for filterList in results {
                    context.delete(filterList)
                }
                try context.save()
                await seedData()
                print("Model reset successfully.")
            } catch {
                print("Failed to reset model: \(error)")
            }
        }
    }

    /// Seeds initial data into the database.
    func seedData() async {
        let context = ModelContext(container)

        // For each pre-defined filter list in FilterListProvider:
        for (index, data) in FilterListProvider.filterListData.enumerated() {
            // We still call the dedicated "saveFilterList" method on FilterListProcessor
            // to keep the code DRY and consistent with the rest of your logic.
            filterListProcessor.saveFilterList(
                to: context,
                id: data.id,
                name: data.name,
                version: "N/A",
                description: data.description,
                category: data.category,
                isEnabled: data.isSelected,
                order: index,
                urlString: data.urlString,
                homepageURL: data.homepageURL,
                downloaded: false
            )

        }

        // Finally, save the inserted records to SwiftData
        do {
            try context.save()
            print("Seed data saved successfully.")
        } catch {
            print("Failed to save seed data: \(error)")
        }
    }

    /// Seeds data only if the database is empty.
    func seedDataIfNeeded() {
        let context = ModelContext(container)
        Task {
            let fetchRequest = FetchDescriptor<FilterList>()
            do {
                let results = try context.fetch(fetchRequest)
                if results.isEmpty {
                    await seedData()
                    print("Seed data inserted.")
                } else {
                    print("Database is not empty.")
                }
            } catch {
                print("Error fetching or saving data: \(error)")
            }
        }
    }
}
