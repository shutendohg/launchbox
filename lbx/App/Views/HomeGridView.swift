import LbxCore
import SwiftData
import SwiftUI

/// What the editor sheet is editing.
struct EditorTarget: Identifiable {
    let id = UUID()
    /// nil when creating a new item.
    var item: LaunchItem?
    var kind: LaunchItem.Kind
    /// Initial group for a new action.
    var parent: LaunchItem?
}

struct HomeGridView: View {
    @Environment(\.modelContext) private var context
    @Environment(ActionRunner.self) private var runner
    @Environment(UIPromptProvider.self) private var promptProvider

    @Query(filter: #Predicate<LaunchItem> { $0.parent == nil }, sort: \LaunchItem.sortIndex)
    private var rootItems: [LaunchItem]

    @State private var isEditing = false
    @State private var editorTarget: EditorTarget?
    @State private var openGroup: LaunchItem?
    @State private var pendingDelete: LaunchItem?
    @State private var isConfirmingDelete = false

    var body: some View {
        @Bindable var runner = runner
        @Bindable var promptProvider = promptProvider

        NavigationStack {
            ScrollView {
                if rootItems.isEmpty {
                    emptyState
                } else {
                    ItemGridView(items: rootItems, isEditing: isEditing, actions: gridActions)
                        .padding()
                }
            }
            .navigationTitle("Lbx")
            .toolbar { toolbar }
        }
        .overlay {
            if let group = openGroup {
                GroupOverlayView(
                    group: group,
                    isEditing: $isEditing,
                    actions: gridActions,
                    onAdd: { editorTarget = EditorTarget(kind: .action, parent: group) },
                    onEditGroup: { editorTarget = EditorTarget(item: group, kind: .group) },
                    onClose: { closeGroup() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.92)))
            }
        }
        .overlay(alignment: .bottom) {
            ToastView(toast: $runner.toast)
        }
        .sheet(item: $editorTarget) { target in
            ActionEditorView(target: target)
        }
        // Swiping the sheet away cancels the run.
        .sheet(isPresented: $promptProvider.isSessionActive, onDismiss: { promptProvider.cancel() }) {
            PromptInputSheet()
        }
        .confirmationDialog(
            deleteTitle,
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible,
            presenting: pendingDelete
        ) { item in
            Button("Delete", role: .destructive) { delete(item) }
        } message: { item in
            if item.isGroup, !item.children.isEmpty {
                Text("The \(item.children.count) action(s) inside this group will also be deleted.")
            }
        }
        .sensoryFeedback(.success, trigger: runner.launchCount)
        .sensoryFeedback(.selection, trigger: isEditing)
        .task { SeedData.seedIfNeeded(context) }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Actions", systemImage: "square.grid.3x3")
        } description: {
            Text("Add an action that opens a URL scheme, like sms: or shortcuts://.")
        } actions: {
            Button("New Action") { editorTarget = EditorTarget(kind: .action) }
                .buttonStyle(.borderedProminent)
        }
        .padding(.top, 80)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !rootItems.isEmpty {
                Button(isEditing ? "Done" : "Edit") {
                    withAnimation(.snappy) { isEditing.toggle() }
                }
                .fontWeight(isEditing ? .semibold : .regular)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button { editorTarget = EditorTarget(kind: .action) } label: {
                    Label("New Action", systemImage: "bolt.fill")
                }
                Button { editorTarget = EditorTarget(kind: .group) } label: {
                    Label("New Group", systemImage: "folder.badge.plus")
                }
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add")
        }
    }

    // MARK: - Actions

    private var gridActions: ItemGridActions {
        ItemGridActions(
            tap: { item in
                if item.isGroup {
                    withAnimation(.snappy) { openGroup = item }
                } else {
                    if item.parent != nil { closeGroup() }
                    runner.run(item)
                }
            },
            edit: { item in editorTarget = EditorTarget(item: item, kind: item.kind) },
            duplicate: { item in
                withAnimation(.snappy) { _ = LaunchItemStore.duplicate(item, context: context) }
            },
            delete: { item in
                pendingDelete = item
                isConfirmingDelete = true
            },
            move: { moving, target in LaunchItemStore.move(moving, onto: target, context: context) }
        )
    }

    private var deleteTitle: String {
        guard let item = pendingDelete else { return "" }
        return "Delete \"\(item.name)\"?"
    }

    private func delete(_ item: LaunchItem) {
        if openGroup?.id == item.id { closeGroup() }
        withAnimation(.snappy) { LaunchItemStore.delete(item, context: context) }
        pendingDelete = nil
    }

    private func closeGroup() {
        withAnimation(.snappy) { openGroup = nil }
    }
}
