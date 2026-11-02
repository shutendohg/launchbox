import SwiftUI

/// Callbacks a grid hands back to its owner.
struct ItemGridActions {
    var tap: @MainActor (LaunchItem) -> Void
    var edit: @MainActor (LaunchItem) -> Void
    var duplicate: @MainActor (LaunchItem) -> Void
    var delete: @MainActor (LaunchItem) -> Void
    var move: @MainActor (_ moving: LaunchItem, _ target: LaunchItem) -> Void
}

/// A 3-column grid of tiles. Normal mode: tap runs, long press shows a context
/// menu. Edit mode: tap edits, drag & drop reorders within this grid.
struct ItemGridView: View {
    let items: [LaunchItem]
    let isEditing: Bool
    let actions: ItemGridActions

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 12, alignment: .top),
        count: 3
    )

    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(items) { item in
                cell(for: item)
            }
        }
    }

    @ViewBuilder
    private func cell(for item: LaunchItem) -> some View {
        if isEditing {
            TileView(item: item, isEditing: true, onDelete: { actions.delete(item) })
                .rotationEffect(.degrees(item.sortIndex.isMultiple(of: 2) ? -1.2 : 1.2))
                // Groups open so their contents can be edited too.
                .onTapGesture { item.isGroup ? actions.tap(item) : actions.edit(item) }
                .draggable(item.id.uuidString) {
                    IconTile(symbol: item.iconSymbol, colorHex: item.colorHex, isGroup: item.isGroup)
                }
                .dropDestination(for: String.self) { droppedIDs, _ in
                    guard let raw = droppedIDs.first,
                          let id = UUID(uuidString: raw),
                          let moving = items.first(where: { $0.id == id }) // same grid only
                    else { return false }
                    withAnimation(.snappy) { actions.move(moving, item) }
                    return true
                }
        } else {
            Button { actions.tap(item) } label: {
                TileView(item: item)
            }
            .buttonStyle(TileButtonStyle())
            .contextMenu {
                Button { actions.edit(item) } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button { actions.duplicate(item) } label: {
                    Label("Duplicate", systemImage: "plus.square.on.square")
                }
                Button(role: .destructive) { actions.delete(item) } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

private struct TileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}
