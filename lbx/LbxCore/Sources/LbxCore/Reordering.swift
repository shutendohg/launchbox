import Foundation

/// Ordering logic for drag & drop in the grid, kept pure so it can be tested.
public enum Reordering {

    /// Returns `order` with `moving` dropped onto `target`'s slot.
    /// Moving forward lands after the target, moving backward lands before it,
    /// matching how grid drag & drop feels. Unknown IDs leave the order unchanged.
    public static func move<ID: Equatable>(_ moving: ID, onto target: ID, in order: [ID]) -> [ID] {
        guard moving != target,
              let from = order.firstIndex(of: moving),
              let to = order.firstIndex(of: target)
        else { return order }

        var result = order
        result.remove(at: from)
        let targetIndex = result.firstIndex(of: target)! // still present: target != moving
        result.insert(moving, at: from < to ? targetIndex + 1 : targetIndex)
        return result
    }
}
