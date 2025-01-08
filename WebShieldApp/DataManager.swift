import Foundation
import SwiftData
import SwiftUI

@MainActor
final class DataManager: ObservableObject {
    private let filterListProcessor = FilterListProcessor()

    func resetModel() {
        let container = try! ModelContainer(for: FilterList.self)
        let context = ModelContext(container)
        do {
            try context.delete(model: FilterList.self)
            try context.save()
            seedData()
            print("Model reset successfully.")
        } catch {
            print("Failed to reset model: \(error)")
        }
    }

    func seedData() {
        let container = try! ModelContainer(for: FilterList.self)
        let context = ModelContext(container)
        for (index, data) in FilterListProvider.filterListData.enumerated() {
            filterListProcessor.saveFilterList(
                to: context,
                id: data.id,
                name: data.name,
                version: "N/A",
                description: data.description,
                category: data.category,
                isEnabled: data.isSelected,
                order: index,
                homepageURL: data.homepageURL,
                downloaded: false
            )
        }
        do {
            try context.save()
            print("Seed data saved successfully.")
        } catch {
            print("Failed to save seed data: \(error)")
        }
    }

    func seedDataIfNeeded() {
        let container = try! ModelContainer(for: FilterList.self)
        let context = ModelContext(container)
        Task {
            let fetchRequest = FetchDescriptor<FilterList>()
            do {
                let results = try context.fetch(fetchRequest)
                if results.isEmpty {
                    seedData()
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
