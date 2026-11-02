import SwiftUI
import UIKit

/// The sheet shown while a run has prompts. It stays presented for the whole
/// run and swaps in one field per prompt, in order of appearance.
struct PromptInputSheet: View {
    @Environment(UIPromptProvider.self) private var provider

    var body: some View {
        NavigationStack {
            Group {
                if let request = provider.current {
                    PromptField(request: request) { provider.submit($0) }
                        .id(request.id) // fresh text state per prompt
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(provider.sessionTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { provider.cancel() }
                        .accessibilityIdentifier("prompt.cancel")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct PromptField: View {
    let request: UIPromptProvider.Request
    let onSubmit: @MainActor (String) -> Void

    @State private var text = ""
    @FocusState private var isFocused: Bool

    private var isLast: Bool { request.position >= request.total }

    var body: some View {
        Form {
            Section {
                TextField(request.label, text: $text)
                    .focused($isFocused)
                    .accessibilityIdentifier("prompt.field")
                    .submitLabel(isLast ? .go : .next)
                    .onSubmit { onSubmit(text) }
            } header: {
                Text(request.label)
            } footer: {
                if request.total > 1 {
                    Text("\(request.position) of \(request.total)")
                }
            }

            Section {
                Button {
                    text = UIPasteboard.general.string ?? text
                } label: {
                    Label("Paste", systemImage: "doc.on.clipboard")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(isLast ? "Open" : "Next") { onSubmit(text) }
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("prompt.submit")
            }
        }
        .onAppear { isFocused = true }
    }
}
