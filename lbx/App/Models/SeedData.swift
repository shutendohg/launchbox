import Foundation
import LbxCore
import SwiftData

/// Populates the grid with sample actions on first launch only, so deleting
/// everything later does not bring the samples back.
@MainActor
enum SeedData {
    private static let seededKey = "didSeedSampleItems"

    /// - Parameter ignoreSeededFlag: Seed an empty store even if seeding happened
    ///   before (used with the in-memory store of UI tests).
    static func seedIfNeeded(
        _ context: ModelContext,
        defaults: UserDefaults = .standard,
        ignoreSeededFlag: Bool = false
    ) {
        guard ignoreSeededFlag || !defaults.bool(forKey: seededKey) else { return }
        defer { defaults.set(true, forKey: seededKey) }

        let existing = (try? context.fetchCount(FetchDescriptor<LaunchItem>())) ?? 0
        guard existing == 0 else { return }

        let rootPresetIDs = ["google", "sms", "tel", "shortcut"]
        let groupPresetIDs = ["google-clipboard", "wikipedia", "translate-clipboard"]

        var index = 0
        for id in rootPresetIDs {
            guard let preset = preset(id) else { continue }
            context.insert(item(from: preset, sortIndex: index))
            index += 1
        }

        let example = LaunchItem(
            kind: .action,
            name: "Example",
            iconSymbol: "safari.fill",
            colorHex: "#30B0C7",
            urlTemplate: "https://example.com",
            sortIndex: index
        )
        context.insert(example)
        index += 1

        let group = LaunchItem(
            kind: .group,
            name: "Lookup",
            iconSymbol: "folder.fill",
            colorHex: "#FF9500",
            sortIndex: index
        )
        context.insert(group)
        for (childIndex, id) in groupPresetIDs.enumerated() {
            guard let preset = preset(id) else { continue }
            let child = item(from: preset, sortIndex: childIndex)
            context.insert(child)
            child.parent = group
        }

        LaunchItemStore.save(context)
    }

    private static func preset(_ id: String) -> ActionPreset? {
        ActionPreset.all.first { $0.id == id }
    }

    private static func item(from preset: ActionPreset, sortIndex: Int) -> LaunchItem {
        LaunchItem(
            kind: .action,
            name: preset.name,
            iconSymbol: preset.iconSymbol,
            colorHex: preset.colorHex,
            urlTemplate: preset.urlTemplate,
            sortIndex: sortIndex
        )
    }
}
