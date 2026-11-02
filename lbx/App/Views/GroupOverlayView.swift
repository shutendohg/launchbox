import SwiftUI

/// A folder-style overlay showing a group's actions above the dimmed home grid.
/// Implemented as an overlay (not a sheet) so the prompt sheet can still be
/// presented while it is visible.
struct GroupOverlayView: View {
    let group: LaunchItem
    @Binding var isEditing: Bool
    let actions: ItemGridActions
    let onAdd: @MainActor () -> Void
    let onEditGroup: @MainActor () -> Void
    let onClose: @MainActor () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("Close group")

            VStack(spacing: 16) {
                header

                let children = group.sortedChildren
                if children.isEmpty {
                    ContentUnavailableView {
                        Label("Empty Group", systemImage: "folder")
                    } description: {
                        Text("Add actions to this group.")
                    } actions: {
                        Button("Add Action", action: onAdd)
                    }
                    .frame(minHeight: 200)
                } else {
                    ScrollView {
                        ItemGridView(items: children, isEditing: isEditing, actions: actions)
                            .padding(.vertical, 8)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .frame(maxHeight: 420)
                }
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .padding(.horizontal, 20)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            IconTile(symbol: group.iconSymbol, colorHex: group.colorHex, size: 32)
            Text(group.name)
                .font(.headline)
                .lineLimit(1)
            Spacer()
            if isEditing {
                Button(action: onEditGroup) {
                    Image(systemName: "pencil.circle.fill")
                }
                .accessibilityLabel("Edit group")
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel("Add action to group")
            }
            Button(isEditing ? "Done" : "Edit") {
                withAnimation(.snappy) { isEditing.toggle() }
            }
            .font(.subheadline.weight(isEditing ? .semibold : .regular))
        }
        .font(.title2)
    }
}
