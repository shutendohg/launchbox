import Foundation
import LaunchboxCore
import SwiftData

/// A cell in the launcher grid: either an action (URL template) or a group.
/// Groups are only allowed at the root (depth 1); the editor enforces this by
/// never offering a group as a parent for a group.
@Model
final class LaunchItem {
    enum Kind: String, Codable, Sendable {
        case action
        case group
    }

    var id: UUID = UUID()
    /// Stored as a raw string so predicates and migrations stay simple.
    var kindRaw: String = Kind.action.rawValue
    var name: String = ""
    var iconSymbol: String = "bolt.fill"
    var colorHex: String = HexColor.defaultHex
    /// Empty for groups.
    var urlTemplate: String = ""
    /// Ordering within the parent (or the root).
    var sortIndex: Int = 0
    /// nil = root. Groups always have a nil parent.
    var parent: LaunchItem?
    @Relationship(deleteRule: .cascade, inverse: \LaunchItem.parent)
    var children: [LaunchItem] = []

    init(
        kind: Kind,
        name: String,
        iconSymbol: String,
        colorHex: String,
        urlTemplate: String = "",
        sortIndex: Int = 0,
        parent: LaunchItem? = nil
    ) {
        self.id = UUID()
        self.kindRaw = kind.rawValue
        self.name = name
        self.iconSymbol = iconSymbol
        self.colorHex = colorHex
        self.urlTemplate = urlTemplate
        self.sortIndex = sortIndex
        self.parent = parent
    }

    var kind: Kind {
        get { Kind(rawValue: kindRaw) ?? .action }
        set { kindRaw = newValue.rawValue }
    }

    var isGroup: Bool { kind == .group }

    var sortedChildren: [LaunchItem] {
        children.sorted { $0.sortIndex < $1.sortIndex }
    }
}
