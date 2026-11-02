import Foundation
import LbxCore
import Observation

/// Bridges `PromptProviding` to SwiftUI. A run with prompts opens one
/// "session" sheet that stays up while each prompt is shown in turn; this
/// avoids dismissing and re-presenting a sheet between consecutive prompts.
@MainActor
@Observable
final class UIPromptProvider: PromptProviding {

    struct Request: Identifiable, Equatable {
        let id = UUID()
        let label: String
        /// 1-based position and total, e.g. "2 of 3".
        let position: Int
        let total: Int
    }

    /// True while the prompt sheet should be on screen. Settable so the sheet
    /// can bind to it; dismissing the sheet must also call `cancel()`.
    var isSessionActive = false
    private(set) var sessionTitle = ""
    private(set) var current: Request?

    @ObservationIgnored private var continuation: CheckedContinuation<String?, Never>?
    @ObservationIgnored private var promptCount = 0
    @ObservationIgnored private var askedCount = 0

    func beginSession(title: String, promptCount: Int) {
        finish(with: nil)
        sessionTitle = title
        self.promptCount = promptCount
        askedCount = 0
        isSessionActive = true
    }

    func endSession() {
        finish(with: nil)
        isSessionActive = false
        current = nil
    }

    // MARK: PromptProviding

    func prompt(label: String) async -> String? {
        finish(with: nil) // never leave a previous continuation dangling
        askedCount += 1
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            self.current = Request(label: label, position: askedCount, total: max(promptCount, askedCount))
        }
    }

    // MARK: UI callbacks

    func submit(_ text: String) {
        finish(with: text)
    }

    /// Cancels the whole run (the resolver aborts on nil).
    func cancel() {
        finish(with: nil)
    }

    private func finish(with value: String?) {
        let pending = continuation
        continuation = nil
        current = nil
        pending?.resume(returning: value)
    }
}
