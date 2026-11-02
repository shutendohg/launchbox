import LbxCore
import SwiftData
import SwiftUI

/// Creates or edits an action or a group. Templates are validated inline and
/// saving is blocked while they have problems, so errors surface here rather
/// than at run time.
struct ActionEditorView: View {
    let target: EditorTarget

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Query private var groups: [LaunchItem]

    @State private var name: String
    @State private var urlTemplate: String
    @State private var iconSymbol: String
    @State private var colorHex: String
    @State private var parentID: UUID?

    init(target: EditorTarget) {
        self.target = target
        let groupKind = LaunchItem.Kind.group.rawValue
        _groups = Query(filter: #Predicate<LaunchItem> { $0.kindRaw == groupKind }, sort: \.sortIndex)
        let item = target.item
        let isGroup = target.kind == .group
        _name = State(initialValue: item?.name ?? "")
        _urlTemplate = State(initialValue: item?.urlTemplate ?? "")
        _iconSymbol = State(initialValue: item?.iconSymbol ?? (isGroup ? "folder.fill" : "bolt.fill"))
        _colorHex = State(initialValue: item?.colorHex ?? (isGroup ? "#FF9500" : HexColor.defaultHex))
        _parentID = State(initialValue: item?.parent?.id ?? target.parent?.id)
    }

    private var isAction: Bool { target.kind == .action }
    private var isNew: Bool { target.item == nil }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedTemplate: String { urlTemplate.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var issue: TemplateIssue? {
        isAction ? TemplateLinter.issue(in: trimmedTemplate) : nil
    }

    private var variables: [TemplateVariable] {
        (try? TemplateLinter.variables(in: trimmedTemplate)) ?? []
    }

    private var canSave: Bool { !trimmedName.isEmpty && issue == nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        IconTile(symbol: iconSymbol, colorHex: colorHex, isGroup: !isAction, size: 52)
                        TextField("Name", text: $name)
                            .font(.title3)
                            .accessibilityIdentifier("editor.name")
                            .submitLabel(.done)
                    }
                    .padding(.vertical, 4)
                }

                if isAction {
                    templateSection
                    if !variables.isEmpty { variablesSection }
                    groupSection
                }

                Section("Icon") {
                    NavigationLink {
                        IconPickerView(selection: $iconSymbol)
                    } label: {
                        LabeledContent("Symbol") {
                            Image(systemName: iconSymbol)
                                .foregroundStyle(Color(hex: colorHex))
                        }
                    }
                }

                Section("Color") {
                    ColorPaletteView(selection: $colorHex)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                        .accessibilityIdentifier("editor.save")
                }
            }
        }
    }

    // MARK: - Sections

    private var templateSection: some View {
        Section {
            TextField("e.g. https://www.google.com/search?q={{prompt:Query}}", text: $urlTemplate, axis: .vertical)
                .font(.body.monospaced())
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .lineLimit(2...6)
                .accessibilityIdentifier("editor.template")

            Menu {
                Button("Prompt: {{prompt:Label}}") { insert("{{prompt:Text}}") }
                Button("Clipboard: {{clipboard}}") { insert("{{clipboard}}") }
                Button("Date: {{date:yyyy-MM-dd}}") { insert("{{date:yyyy-MM-dd}}") }
            } label: {
                Label("Insert Variable", systemImage: "curlybraces")
            }

            NavigationLink {
                PresetPickerView { apply($0) }
            } label: {
                Label("Choose Preset", systemImage: "sparkles.rectangle.stack")
            }
        } header: {
            Text("URL Template")
        } footer: {
            if let issue, !trimmedTemplate.isEmpty {
                Label(issue.message, systemImage: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("editor.issue")
            } else {
                Text("Values are percent-encoded unless you add |raw, e.g. {{clipboard|raw}}.")
            }
        }
    }

    private var variablesSection: some View {
        Section("Asked When Run") {
            ForEach(Array(variables.enumerated()), id: \.offset) { _, variable in
                VariableRow(variable: variable)
            }
        }
    }

    private var groupSection: some View {
        Section("Group") {
            Picker("Group", selection: $parentID) {
                Text("None").tag(UUID?.none)
                ForEach(groups) { group in
                    Label(group.name, systemImage: group.iconSymbol).tag(UUID?.some(group.id))
                }
            }
            .accessibilityIdentifier("editor.group")
        }
    }

    private var title: String {
        switch (isNew, isAction) {
        case (true, true): return "New Action"
        case (true, false): return "New Group"
        case (false, true): return "Edit Action"
        case (false, false): return "Edit Group"
        }
    }

    // MARK: - Actions

    private func insert(_ snippet: String) {
        urlTemplate += snippet
    }

    private func apply(_ preset: ActionPreset) {
        urlTemplate = preset.urlTemplate
        if isNew || trimmedName.isEmpty {
            name = preset.name
            iconSymbol = preset.iconSymbol
            colorHex = preset.colorHex
        }
    }

    private func save() {
        guard canSave else { return }
        let parent = isAction ? groups.first { $0.id == parentID } : nil

        if let item = target.item {
            item.name = trimmedName
            item.iconSymbol = iconSymbol
            item.colorHex = colorHex
            if isAction {
                item.urlTemplate = trimmedTemplate
                LaunchItemStore.reparent(item, to: parent, context: context)
            }
            LaunchItemStore.save(context)
        } else {
            let item = LaunchItem(
                kind: target.kind,
                name: trimmedName,
                iconSymbol: iconSymbol,
                colorHex: colorHex,
                urlTemplate: isAction ? trimmedTemplate : ""
            )
            LaunchItemStore.insert(item, into: parent, context: context)
        }
        dismiss()
    }
}

private struct VariableRow: View {
    let variable: TemplateVariable

    var body: some View {
        HStack {
            Image(systemName: symbol)
                .foregroundStyle(.tint)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                if let detail = variable.detail {
                    Text(detail)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(variable.isRaw ? "raw" : "encoded")
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary, in: Capsule())
        }
    }

    private var title: String {
        switch variable.name {
        case .prompt: return "Text input"
        case .clipboard: return "Clipboard"
        case .date: return "Date"
        }
    }

    private var symbol: String {
        switch variable.name {
        case .prompt: return "text.cursor"
        case .clipboard: return "doc.on.clipboard"
        case .date: return "calendar"
        }
    }
}

/// Lists the built-in presets; picking one pops back to the editor.
private struct PresetPickerView: View {
    let onSelect: @MainActor (ActionPreset) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(ActionPreset.all) { preset in
            Button {
                onSelect(preset)
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    IconTile(symbol: preset.iconSymbol, colorHex: preset.colorHex, size: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(preset.name)
                            .foregroundStyle(.primary)
                        Text(preset.summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(preset.urlTemplate)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .navigationTitle("Presets")
        .navigationBarTitleDisplayMode(.inline)
    }
}
