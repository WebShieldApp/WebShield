import Foundation
import SwiftData
import SwiftUI

@Model
final class TrustedSite {
    @Attribute(.unique) var id: String
    var domain: String

    init(domain: String) {
        self.id = UUID().uuidString
        self.domain = domain
    }
}
