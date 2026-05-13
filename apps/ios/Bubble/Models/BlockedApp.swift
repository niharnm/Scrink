import Foundation

struct BlockingOption: Identifiable, Hashable {
    let id: String
    let label: String
    var isEnabled: Bool
}

struct BlockedApp: Identifiable, Hashable {
    let id: String
    let name: String
    let iconName: String   // SF Symbol name
    let platform: String? // Platform identifier for custom icons (instagram, facebook, etc.)
    var options: [BlockingOption]

    static func == (lhs: BlockedApp, rhs: BlockedApp) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
