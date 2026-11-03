import XCTest
@testable import LaunchboxCore

/// Returns queued answers in order; `nil` in the queue simulates a cancel.
private actor StubPromptProvider: PromptProviding {
    private var answers: [String?]
    private(set) var askedLabels: [String] = []

    init(answers: [String?]) { self.answers = answers }

    func prompt(label: String) async -> String? {
        askedLabels.append(label)
        guard !answers.isEmpty else {
            XCTFail("Prompted more times than expected (label: \(label))")
            return nil
        }
        return answers.removeFirst()
    }
}

private struct StubContext: ResolutionContext {
    var promptProvider: any PromptProviding
    var clipboardText: String = ""
    // 2026-07-20 09:05:03 UTC
    var now: Date = Date(timeIntervalSince1970: 1_784_538_303)
    var timeZone: TimeZone = TimeZone(identifier: "UTC")!
    var locale: Locale = Locale(identifier: "en_US_POSIX")
}

final class TemplateResolverTests: XCTestCase {

    private func resolve(
        _ template: String,
        answers: [String?] = [],
        clipboard: String = ""
    ) async throws -> (String, [String]) {
        let provider = StubPromptProvider(answers: answers)
        let context = StubContext(promptProvider: provider, clipboardText: clipboard)
        let result = try await TemplateResolver.resolve(template, context: context)
        return (result, await provider.askedLabels)
    }

    // MARK: - Literals

    func test_literalOnlyTemplate_isReturnedUnchanged() async throws {
        let (result, asked) = try await resolve("sms:")
        XCTAssertEqual(result, "sms:")
        XCTAssertEqual(asked, [])
    }

    func test_literalsAreNeverEncoded() async throws {
        let (result, _) = try await resolve("https://a.com/?x=1&y=日本")
        XCTAssertEqual(result, "https://a.com/?x=1&y=日本")
    }

    // MARK: - prompt

    func test_prompt_insertsUserInput() async throws {
        let (result, asked) = try await resolve("https://s.com/?q={{prompt:Query}}", answers: ["swift"])
        XCTAssertEqual(result, "https://s.com/?q=swift")
        XCTAssertEqual(asked, ["Query"])
    }

    func test_promptWithoutArg_usesDefaultLabel() async throws {
        let (_, asked) = try await resolve("{{prompt}}", answers: ["x"])
        XCTAssertEqual(asked, [TemplateResolver.defaultPromptLabel])
    }

    func test_multiplePrompts_areAskedInOrderOfAppearance() async throws {
        let (result, asked) = try await resolve(
            "mailto:{{prompt:To}}?subject={{prompt:Subject}}",
            answers: ["a@b.c", "hi"]
        )
        XCTAssertEqual(asked, ["To", "Subject"])
        XCTAssertEqual(result, "mailto:a@b.c?subject=hi")
    }

    func test_cancelledPrompt_throwsCancelledAndStopsAsking() async throws {
        let provider = StubPromptProvider(answers: [nil])
        let context = StubContext(promptProvider: provider)
        do {
            _ = try await TemplateResolver.resolve("{{prompt:A}}{{prompt:B}}", context: context)
            XCTFail("Expected cancellation")
        } catch {
            XCTAssertEqual(error as? TemplateResolutionError, .cancelled)
        }
        let asked = await provider.askedLabels
        XCTAssertEqual(asked, ["A"])
    }

    // MARK: - clipboard

    func test_clipboard_insertsClipboardText() async throws {
        let (result, _) = try await resolve("x://?t={{clipboard}}", clipboard: "hello")
        XCTAssertEqual(result, "x://?t=hello")
    }

    func test_emptyClipboard_insertsEmptyString() async throws {
        let (result, _) = try await resolve("x://?t={{clipboard}}", clipboard: "")
        XCTAssertEqual(result, "x://?t=")
    }

    // MARK: - date

    func test_dateWithoutArg_usesDefaultFormat() async throws {
        let (result, _) = try await resolve("{{date}}")
        XCTAssertEqual(result, "2026-07-20")
    }

    func test_dateWithPattern_formatsNow() async throws {
        let (result, _) = try await resolve("{{date:HH:mm:ss|raw}}")
        XCTAssertEqual(result, "09:05:03")
    }

    func test_dateIsPercentEncodedByDefault() async throws {
        let (result, _) = try await resolve("{{date:yyyy/MM/dd HH:mm}}")
        XCTAssertEqual(result, "2026/07/20%2009:05")
    }

    // MARK: - Encoding

    func test_values_arePercentEncoded() async throws {
        let (result, _) = try await resolve("{{prompt}}", answers: ["a b&c=d+e?f#g/h:i 日本"])
        XCTAssertEqual(result, "a%20b%26c%3Dd%2Be%3Ff%23g/h:i%20%E6%97%A5%E6%9C%AC")
    }

    func test_rawModifier_insertsValueUnchanged() async throws {
        let (result, _) = try await resolve(
            "{{clipboard|raw}}",
            clipboard: "https://example.com/?a=1&b=2"
        )
        XCTAssertEqual(result, "https://example.com/?a=1&b=2")
    }

    func test_percentEncode_matchesSpecifiedCharacterSet() {
        XCTAssertEqual(TemplateResolver.percentEncode("&=+?#"), "%26%3D%2B%3F%23")
        XCTAssertEqual(TemplateResolver.percentEncode("abcXYZ019-._~/:@!$'()*,;"), "abcXYZ019-._~/:@!$'()*,;")
        XCTAssertEqual(TemplateResolver.percentEncode("%"), "%25")
    }

    // MARK: - Errors

    func test_invalidTemplateString_throwsParseError() async {
        let context = StubContext(promptProvider: StubPromptProvider(answers: []))
        do {
            _ = try await TemplateResolver.resolve("{{bogus}}", context: context)
            XCTFail("Expected parse error")
        } catch {
            XCTAssertEqual(error as? TemplateParseError, .unknownName("bogus", offset: 0))
        }
    }
}
