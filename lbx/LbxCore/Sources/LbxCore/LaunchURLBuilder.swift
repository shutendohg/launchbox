import Foundation

public enum LaunchURLError: Error, Equatable, Sendable {
    case empty
    case missingScheme
    case invalidScheme(String)
    case containsWhitespace
    case malformed(String)

    public var message: String {
        switch self {
        case .empty:
            return "The URL is empty."
        case .missingScheme:
            return "The URL has no scheme (e.g. \"https:\" or \"sms:\")."
        case .invalidScheme(let scheme):
            return "\"\(scheme)\" is not a valid URL scheme."
        case .containsWhitespace:
            return "The URL contains spaces. Use a variable (encoded by default) or %20 instead."
        case .malformed(let string):
            return "Not a valid URL: \(string)"
        }
    }
}

extension LaunchURLError: LocalizedError {
    public var errorDescription: String? { message }
}

/// Turns a resolved template string into a `URL`, rejecting strings that
/// `UIApplication.open` could never handle. It does not check whether any
/// installed app handles the scheme; that is only known when opening.
public enum LaunchURLBuilder {

    public static func build(_ string: String) throws -> URL {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw LaunchURLError.empty }

        guard let colon = trimmed.firstIndex(of: ":") else { throw LaunchURLError.missingScheme }
        let scheme = String(trimmed[..<colon])
        guard !scheme.isEmpty else { throw LaunchURLError.missingScheme }
        // If what precedes the first ":" looks like a host/path, there is no scheme at all.
        if scheme.contains("/") { throw LaunchURLError.missingScheme }
        guard isValidScheme(scheme) else { throw LaunchURLError.invalidScheme(scheme) }

        if trimmed.unicodeScalars.contains(where: { CharacterSet.whitespacesAndNewlines.contains($0) }) {
            throw LaunchURLError.containsWhitespace
        }

        let encoded = percentEncodeNonASCII(trimmed)
        guard let url = URLComponents(string: encoded)?.url ?? URL(string: encoded) else {
            throw LaunchURLError.malformed(trimmed)
        }
        return url
    }

    /// RFC 3986: scheme = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
    static func isValidScheme(_ scheme: String) -> Bool {
        let scalars = Array(scheme.unicodeScalars)
        guard let first = scalars.first, first.isASCII, first.properties.isAlphabetic else { return false }
        return scalars.dropFirst().allSatisfy { scalar in
            guard scalar.isASCII else { return false }
            return scalar.properties.isAlphabetic
                || ("0"..."9").contains(scalar)
                || scalar == "+" || scalar == "-" || scalar == "."
        }
    }

    /// Converts an IRI-ish string to a URI by percent-encoding non-ASCII scalars as UTF-8.
    static func percentEncodeNonASCII(_ string: String) -> String {
        var result = ""
        for scalar in string.unicodeScalars {
            if scalar.isASCII {
                result.unicodeScalars.append(scalar)
            } else {
                for byte in String(scalar).utf8 {
                    result += String(format: "%%%02X", byte)
                }
            }
        }
        return result
    }
}
