import Foundation

/// A problem detected when saving a template in the editor.
public enum TemplateIssue: Equatable, Sendable {
    case parse(TemplateParseError)
    case url(LaunchURLError)

    public var message: String {
        switch self {
        case .parse(let error): return error.message
        case .url(let error): return error.message
        }
    }
}

/// A human-readable summary of one tag, for the editor's variable preview.
public struct TemplateVariable: Equatable, Sendable {
    public let name: TemplateTagName
    /// Prompt label or effective date pattern; nil for clipboard / unlabeled prompt.
    public let detail: String?
    public let isRaw: Bool
}

/// Static (save-time) checks for URL templates, so errors surface in the
/// editor instead of at run time.
public enum TemplateLinter {

    /// Returns the first problem with `template`, or nil if it looks launchable.
    public static func issue(in template: String) -> TemplateIssue? {
        let tokens: [TemplateToken]
        do {
            tokens = try TemplateParser.parse(template)
        } catch let error as TemplateParseError {
            return .parse(error)
        } catch {
            return nil
        }

        guard !tokens.isEmpty else { return .url(.empty) }

        for case .literal(let text) in tokens
        where text.unicodeScalars.contains(where: { CharacterSet.whitespacesAndNewlines.contains($0) }) {
            return .url(.containsWhitespace)
        }

        // If the template starts with a variable, the scheme is only known at run time.
        guard case .literal = tokens[0] else { return nil }

        let sample = tokens.map { token -> String in
            switch token {
            case .literal(let text): return text
            case .tag: return "x"
            }
        }.joined()

        do {
            _ = try LaunchURLBuilder.build(sample)
            return nil
        } catch let error as LaunchURLError {
            return .url(error)
        } catch {
            return nil
        }
    }

    /// Describes each tag in order of appearance.
    public static func variables(in template: String) throws -> [TemplateVariable] {
        try TemplateParser.parse(template).compactMap { token in
            guard case .tag(let name, let arg, let modifiers) = token else { return nil }
            let detail: String?
            switch name {
            case .prompt: detail = arg
            case .clipboard: detail = nil
            case .date: detail = arg ?? TemplateResolver.defaultDateFormat
            }
            return TemplateVariable(name: name, detail: detail, isRaw: modifiers.contains(.raw))
        }
    }
}
