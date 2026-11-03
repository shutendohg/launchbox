import Foundation
import LaunchboxCore
import SwiftData

/// Mutations on the launcher tree that need to keep `sortIndex` consistent.
@MainActor
enum LaunchItemStore {

    /// Items in a container (root when `parent` is nil), in display order.
    static func siblings(of parent: LaunchItem?, in context: ModelContext) -> [LaunchItem] {
        if let parent { return parent.sortedChildren }
        let descriptor = FetchDescriptor<LaunchItem>(
            predicate: #Predicate { $0.parent == nil },
            sortBy: [SortDescriptor(\.sortIndex)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    static func nextSortIndex(in parent: LaunchItem?, context: ModelContext) -> Int {
        (siblings(of: parent, in: context).map(\.sortIndex).max() ?? -1) + 1
    }

    /// Inserts a new item at the end of `parent` (or root).
    static func insert(_ item: LaunchItem, into parent: LaunchItem?, context: ModelContext) {
        item.sortIndex = nextSortIndex(in: parent, context: context)
        context.insert(item)
        item.parent = parent
        save(context)
    }

    /// Moves an item to another container, appending it at the end.
    /// Does not save; the caller saves once after all of its edits.
    static func reparent(_ item: LaunchItem, to newParent: LaunchItem?, context: ModelContext) {
        guard item.parent?.id != newParent?.id else { return }
        let oldParent = item.parent
        item.sortIndex = nextSortIndex(in: newParent, context: context)
        item.parent = newParent
        renumber(siblings(of: oldParent, in: context).filter { $0.id != item.id })
    }

    /// Drag & drop: places `moving` at `target`'s slot. Both must share a container.
    static func move(_ moving: LaunchItem, onto target: LaunchItem, context: ModelContext) {
        guard moving.parent?.id == target.parent?.id else { return }
        let items = siblings(of: moving.parent, in: context)
        let newOrder = Reordering.move(moving.id, onto: target.id, in: items.map(\.id))
        let byID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        renumber(newOrder.compactMap { byID[$0] })
        save(context)
    }

    /// Copies an item (and a group's children) right after the original.
    @discardableResult
    static func duplicate(_ item: LaunchItem, context: ModelContext) -> LaunchItem {
        let copy = LaunchItem(
            kind: item.kind,
            name: item.name + " Copy",
            iconSymbol: item.iconSymbol,
            colorHex: item.colorHex,
            urlTemplate: item.urlTemplate
        )
        context.insert(copy)
        copy.parent = item.parent

        for child in item.sortedChildren {
            let childCopy = LaunchItem(
                kind: child.kind,
                name: child.name,
                iconSymbol: child.iconSymbol,
                colorHex: child.colorHex,
                urlTemplate: child.urlTemplate,
                sortIndex: child.sortIndex
            )
            context.insert(childCopy)
            childCopy.parent = copy
        }

        var order = siblings(of: item.parent, in: context).filter { $0.id != copy.id }
        let index = (order.firstIndex { $0.id == item.id } ?? order.count - 1) + 1
        order.insert(copy, at: index)
        renumber(order)
        save(context)
        return copy
    }

    /// Deletes an item; a group's children are deleted by the cascade rule.
    static func delete(_ item: LaunchItem, context: ModelContext) {
        let parent = item.parent
        let id = item.id
        context.delete(item)
        renumber(siblings(of: parent, in: context).filter { $0.id != id })
        save(context)
    }

    static func renumber(_ items: [LaunchItem]) {
        for (index, item) in items.enumerated() where item.sortIndex != index {
            item.sortIndex = index
        }
    }

    static func save(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            assertionFailure("Failed to save: \(error)")
        }
    }
}
