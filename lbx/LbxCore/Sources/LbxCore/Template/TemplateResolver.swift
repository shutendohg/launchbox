import Foundation

/// Supplies user input for `{{prompt}}` tags. Implemented by the UI layer.
public protocol PromptProviding: Sendable {
    /// Returns user input, or nil if the user cancelled.
    func prompt(label: String) async -> String?
}

/// Everything the resolver needs from the outside world, injected so that
/// resolution is deterministic under test.
public protocol ResolutionContext: Sendable {
    var promptProvider: any PromptProviding { get }
    /// Clipboard text at the time of execution (injected, not read from UIPasteboard directly).
    var clipboardText: String { get }
    /// The instant used for `{{date}}` tags.
    var now: Date { get }
    /// Time zone used for `{{date}}` tags. Defaults to `.current`.
    var timeZone: TimeZone { get }
    /// Locale used for `{{date}}` tags. Defaults to `.current`.
    var locale: Locale { get }
}

extension ResolutionContext {
    public var timeZone: TimeZone { .current }
    public var locale: Locale { .current }
}

public enum TemplateResolutionError: Error, Equatable, Sendable {
    /// The user cancelled a prompt; the whole run must be aborted.
    case cancelled
}

public enum TemplateResolver {

    /// Title shown for `{{prompt}}` tags without an arg.
    public static let defaultPromptLabel = "Input"
    /// Pattern used for `{{date}}` tags without an arg.
    public static let defaultDateFormat = "yyyy-MM-dd"

    /// `urlQueryAllowed` minus `&=+?#`: values stay safe inside a query component.
    public static let encodingAllowedCharacters: CharacterSet = {
        var set = CharacterSet.urlQueryAllowed
        set.remove(charactersIn: "&=+?#")
        return set
    }()

    /// Parses and resolves a template string in one step.
    public static func resolve(_ template: String, context: some ResolutionContext) async throws -> String {
        try await resolve(TemplateParser.parse(template), context: context)
    }

    /// Resolves tokens left to right. Prompts are asked in order of appearance;
    /// a cancelled prompt throws `TemplateResolutionError.cancelled` immediately.
    public static func resolve(_ tokens: [TemplateToken], context: some ResolutionContext) async throws -> String {
        var output = ""
        for token in tokens {
            switch token {
            case .literal(let text):
                output += text
            case .tag(let name, let arg, let modifiers):
                let value: String
                switch name {
                case .prompt:
                    guard let input = await context.promptProvider.prompt(label: arg ?? defaultPromptLabel) else {
                        throw TemplateResolutionError.cancelled
                    }
                    value = input
                case .clipboard:
                    value = context.clipboardText
                case .date:
                    value = formatDate(
                        context.now,
                        pattern: arg ?? defaultDateFormat,
                        timeZone: context.timeZone,
                        locale: context.locale
                    )
                }
                output += modifiers.contains(.raw) ? value : percentEncode(value)
            }
        }
        return output
    }

    public static func percentEncode(_ value: String) -> String {
        // Only fails for invalid UTF-16 (lone surrogates), which Swift Strings cannot hold.
        value.addingPercentEncoding(withAllowedCharacters: encodingAllowedCharacters) ?? value
    }

    static func formatDate(_ date: Date, pattern: String, timeZone: TimeZone, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }
}
