import Foundation
import LbxCore
import Observation
import UIKit

/// Opens URLs. Abstracted so previews and future tests can avoid UIApplication.
protocol URLOpening: Sendable {
    @MainActor func open(_ url: URL) async -> Bool
}

struct SystemURLOpener: URLOpening {
    @MainActor func open(_ url: URL) async -> Bool {
        await UIApplication.shared.open(url)
    }
}

/// Logs instead of opening; used by SwiftUI previews.
struct PreviewURLOpener: URLOpening {
    @MainActor func open(_ url: URL) async -> Bool {
        print("Would open \(url)")
        return true
    }
}

private struct AppResolutionContext: ResolutionContext {
    let promptProvider: any PromptProviding
    let clipboardText: String
    let now: Date
}

/// Runs actions: parse (cached) → resolve → build URL → open → report errors.
/// Views only hand over the item to run.
@MainActor
@Observable
final class ActionRunner {

    struct Toast: Identifiable, Equatable {
        let id = UUID()
        let message: String
    }

    var toast: Toast?
    private(set) var isRunning = false
    /// Incremented on every successful launch; drives haptic feedback.
    private(set) var launchCount = 0

    let promptProvider: UIPromptProvider
    @ObservationIgnored private let opener: any URLOpening
    @ObservationIgnored private var tokenCache: [String: [TemplateToken]] = [:]

    init(promptProvider: UIPromptProvider, opener: any URLOpening = SystemURLOpener()) {
        self.promptProvider = promptProvider
        self.opener = opener
    }

    func run(_ item: LaunchItem) {
        guard item.kind == .action, !isRunning else { return }
        let name = item.name
        let template = item.urlTemplate
        Task { await run(template: template, name: name) }
    }

    func run(template: String, name: String) async {
        guard !isRunning else { return }
        isRunning = true
        defer { isRunning = false }

        do {
            // Templates are validated when saved; this is a defensive re-check.
            let tokens = try tokens(for: template)

            let promptCount = tokens.filter(\.isPrompt).count
            if promptCount > 0 {
                promptProvider.beginSession(title: name, promptCount: promptCount)
            }
            defer { if promptCount > 0 { promptProvider.endSession() } }

            let context = AppResolutionContext(
                promptProvider: promptProvider,
                clipboardText: usesClipboard(tokens) ? (UIPasteboard.general.string ?? "") : "",
                now: .now
            )
            let resolved = try await TemplateResolver.resolve(tokens, context: context)
            let url = try LaunchURLBuilder.build(resolved)

            if promptCount > 0 {
                promptProvider.endSession()
                // Let the prompt sheet start dismissing before leaving the app.
                try? await Task.sleep(for: .milliseconds(350))
            }

            if await opener.open(url) {
                launchCount += 1
            } else {
                showError("Couldn't open: \(url.absoluteString)")
            }
        } catch TemplateResolutionError.cancelled {
            // The user cancelled a prompt: abort silently.
        } catch {
            showError(error.localizedDescription)
        }
    }

    func showError(_ message: String) {
        toast = Toast(message: message)
    }

    private func tokens(for template: String) throws -> [TemplateToken] {
        if let cached = tokenCache[template] { return cached }
        let tokens = try TemplateParser.parse(template)
        tokenCache[template] = tokens
        return tokens
    }

    private func usesClipboard(_ tokens: [TemplateToken]) -> Bool {
        // Read the pasteboard only when needed, so iOS shows its paste prompt only then.
        tokens.contains {
            if case .tag(name: .clipboard, _, _) = $0 { return true }
            return false
        }
    }
}
