import Foundation

/// A syntax error in a URL template. Offsets are character (grapheme) offsets
/// of the opening `{{` of the offending tag.
public enum TemplateParseError: Error, Equatable, Sendable {
    case unclosedTag(offset: Int)
    case emptyTag(offset: Int)
    case nestedTag(offset: Int)
    case unknownName(String, offset: Int)
    case unknownModifier(String, offset: Int)
    case unexpectedArgument(String, offset: Int)

    /// A short, user-facing explanation of the error.
    public var message: String {
        switch self {
        case .unclosedTag(let offset):
            return "Tag at position \(offset + 1) is missing its closing \"}}\"."
        case .emptyTag(let offset):
            return "Tag at position \(offset + 1) is empty."
        case .nestedTag(let offset):
            return "Tag at position \(offset + 1) contains another \"{{\"; tags cannot be nested."
        case .unknownName(let name, let offset):
            let known = TemplateTagName.allCases.map(\.rawValue).joined(separator: ", ")
            return "Unknown variable \"\(name)\" at position \(offset + 1). Use one of: \(known)."
        case .unknownModifier(let modifier, let offset):
            let known = TemplateModifier.allCases.map(\.rawValue).joined(separator: ", ")
            return "Unknown modifier \"\(modifier)\" at position \(offset + 1). Use one of: \(known)."
        case .unexpectedArgument(let name, let offset):
            return "\"\(name)\" at position \(offset + 1) does not take an argument."
        }
    }
}

extension TemplateParseError: LocalizedError {
    public var errorDescription: String? { message }
}

/// Parses URL templates of the form:
///
///     template := ( literal | tag )*
///     tag      := "{{" name ( ":" arg )? ( "|" modifier )* "}}"
///     name     := "prompt" | "clipboard" | "date"
///     modifier := "raw"
///
/// There is no escape syntax: a literal `{{` cannot be expressed.
public enum TemplateParser {

    public static func parse(_ template: String) throws -> [TemplateToken] {
        let chars = Array(template)
        var tokens: [TemplateToken] = []
        var literal = ""
        var i = 0

        func isOpen(at index: Int) -> Bool {
            index + 1 < chars.count && chars[index] == "{" && chars[index + 1] == "{"
        }
        func isClose(at index: Int) -> Bool {
            index + 1 < chars.count && chars[index] == "}" && chars[index + 1] == "}"
        }

        while i < chars.count {
            guard isOpen(at: i) else {
                literal.append(chars[i])
                i += 1
                continue
            }

            let tagStart = i
            var j = i + 2
            var closeIndex: Int?
            while j < chars.count {
                if isClose(at: j) { closeIndex = j; break }
                if isOpen(at: j) { throw TemplateParseError.nestedTag(offset: tagStart) }
                j += 1
            }
            guard let close = closeIndex else {
                throw TemplateParseError.unclosedTag(offset: tagStart)
            }

            let body = String(chars[(tagStart + 2)..<close])
            let token = try parseTagBody(body, offset: tagStart)

            if !literal.isEmpty {
                tokens.append(.literal(literal))
                literal = ""
            }
            tokens.append(token)
            i = close + 2
        }

        if !literal.isEmpty {
            tokens.append(.literal(literal))
        }
        return tokens
    }

    private static func parseTagBody(_ body: String, offset: Int) throws -> TemplateToken {
        guard !body.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw TemplateParseError.emptyTag(offset: offset)
        }

        // Modifiers are split off first so that an arg may contain ":" (e.g. "HH:mm").
        var parts = body.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        let head = parts.removeFirst()

        let nameAndArg = head.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        let rawName = nameAndArg[0].trimmingCharacters(in: .whitespaces)
        let arg = nameAndArg.count > 1 ? String(nameAndArg[1]) : nil

        guard let name = TemplateTagName(rawValue: rawName) else {
            throw TemplateParseError.unknownName(rawName, offset: offset)
        }

        let normalizedArg = (arg?.isEmpty ?? true) ? nil : arg
        if normalizedArg != nil && !name.acceptsArgument {
            throw TemplateParseError.unexpectedArgument(name.rawValue, offset: offset)
        }

        let modifiers = try parts.map { part -> TemplateModifier in
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            guard let modifier = TemplateModifier(rawValue: trimmed) else {
                throw TemplateParseError.unknownModifier(trimmed, offset: offset)
            }
            return modifier
        }

        return .tag(name: name, arg: normalizedArg, modifiers: modifiers)
    }
}
