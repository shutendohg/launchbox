import Foundation

/// The variable kinds a template tag can reference.
public enum TemplateTagName: String, CaseIterable, Sendable, Hashable {
    /// Asks the user for free-form text at run time. The arg is used as the prompt title.
    case prompt
    /// The clipboard's text at run time (empty if none).
    case clipboard
    /// The current date/time, formatted with a `DateFormatter` pattern (arg, default `yyyy-MM-dd`).
    case date

    /// Whether this tag accepts a `:arg` part.
    var acceptsArgument: Bool {
        switch self {
        case .prompt, .date: return true
        case .clipboard: return false
        }
    }
}

/// Modifiers that change how a resolved value is inserted.
public enum TemplateModifier: String, CaseIterable, Sendable, Hashable {
    /// Insert the value as-is instead of percent-encoding it.
    case raw
}

/// A lexical unit of a URL template.
public enum TemplateToken: Sendable, Hashable {
    case literal(String)
    case tag(name: TemplateTagName, arg: String?, modifiers: [TemplateModifier])
}

extension TemplateToken {
    /// True if the token requires user interaction to resolve.
    public var isPrompt: Bool {
        if case .tag(name: .prompt, _, _) = self { return true }
        return false
    }
}
