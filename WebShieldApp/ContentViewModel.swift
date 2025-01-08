import Foundation
import SwiftData

final class ContentViewModel: ObservableObject {
    @Published var selectedCategory: FilterListCategory = .all

    @MainActor
    init(context: ModelContext) {

    }
}
