import XCTest
@testable import LbxCore

final class TemplateParserTests: XCTestCase {

    // MARK: - Valid templates

    func test_emptyString_parsesToNoTokens() throws {
        XCTAssertEqual(try TemplateParser.parse(""), [])
    }

    func test_literalOnly_parsesToSingleLiteral() throws {
        XCTAssertEqual(
            try TemplateParser.parse("https://example.com"),
            [.literal("https://example.com")]
        )
    }

    func test_bareTag_hasNoArgAndNoModifiers() throws {
        XCTAssertEqual(
            try TemplateParser.parse("{{prompt}}"),
            [.tag(name: .prompt, arg: nil, modifiers: [])]
        )
    }

    func test_tagMixedWithLiterals_keepsOrder() throws {
        XCTAssertEqual(
            try TemplateParser.parse("https://www.google.com/search?q={{prompt:Query}}&hl=ja"),
            [
                .literal("https://www.google.com/search?q="),
                .tag(name: .prompt, arg: "Query", modifiers: []),
                .literal("&hl=ja"),
            ]
        )
    }

    func test_multipleAdjacentTags_produceSeparateTokens() throws {
        XCTAssertEqual(
            try TemplateParser.parse("{{clipboard}}{{date}}"),
            [
                .tag(name: .clipboard, arg: nil, modifiers: []),
                .tag(name: .date, arg: nil, modifiers: []),
            ]
        )
    }

    func test_argIsSplitOnFirstColonOnly_soTimeFormatsSurvive() throws {
        XCTAssertEqual(
            try TemplateParser.parse("{{date:HH:mm}}"),
            [.tag(name: .date, arg: "HH:mm", modifiers: [])]
        )
    }

    func test_argMayContainNonAsciiAndSpaces() throws {
        XCTAssertEqual(
            try TemplateParser.parse("{{prompt:Shortcut 名}}"),
            [.tag(name: .prompt, arg: "Shortcut 名", modifiers: [])]
        )
    }

    func test_emptyArg_isNormalizedToNil() throws {
        XCTAssertEqual(
            try TemplateParser.parse("{{prompt:}}"),
            [.tag(name: .prompt, arg: nil, modifiers: [])]
        )
    }

    func test_rawModifier_isParsed() throws {
        XCTAssertEqual(
            try TemplateParser.parse("{{clipboard|raw}}"),
            [.tag(name: .clipboard, arg: nil, modifiers: [.raw])]
        )
    }

    func test_argAndModifier_areBothParsed() throws {
        XCTAssertEqual(
            try TemplateParser.parse("{{prompt:Path|raw}}"),
            [.tag(name: .prompt, arg: "Path", modifiers: [.raw])]
        )
    }

    func test_whitespaceAroundNameAndModifier_isIgnored() throws {
        XCTAssertEqual(
            try TemplateParser.parse("{{ clipboard | raw }}"),
            [.tag(name: .clipboard, arg: nil, modifiers: [.raw])]
        )
    }

    func test_singleBracesAndClosingBraces_areLiterals() throws {
        XCTAssertEqual(
            try TemplateParser.parse("a{b}c}}d"),
            [.literal("a{b}c}}d")]
        )
    }

    // MARK: - Invalid templates

    func test_unclosedTag_throws() {
        XCTAssertThrowsError(try TemplateParser.parse("https://x.com/?q={{prompt")) { error in
            XCTAssertEqual(error as? TemplateParseError, .unclosedTag(offset: 17))
        }
    }

    func test_unknownName_throws() {
        XCTAssertThrowsError(try TemplateParser.parse("{{foo}}")) { error in
            XCTAssertEqual(error as? TemplateParseError, .unknownName("foo", offset: 0))
        }
    }

    func test_emptyTag_throws() {
        XCTAssertThrowsError(try TemplateParser.parse("x{{}}")) { error in
            XCTAssertEqual(error as? TemplateParseError, .emptyTag(offset: 1))
        }
    }

    func test_whitespaceOnlyTag_throws() {
        XCTAssertThrowsError(try TemplateParser.parse("{{  }}")) { error in
            XCTAssertEqual(error as? TemplateParseError, .emptyTag(offset: 0))
        }
    }

    func test_unknownModifier_throws() {
        XCTAssertThrowsError(try TemplateParser.parse("{{clipboard|upper}}")) { error in
            XCTAssertEqual(error as? TemplateParseError, .unknownModifier("upper", offset: 0))
        }
    }

    func test_emptyModifier_throws() {
        XCTAssertThrowsError(try TemplateParser.parse("{{clipboard|}}")) { error in
            XCTAssertEqual(error as? TemplateParseError, .unknownModifier("", offset: 0))
        }
    }

    func test_nestedOpeningBraces_throws() {
        XCTAssertThrowsError(try TemplateParser.parse("{{prompt:{{x}}")) { error in
            XCTAssertEqual(error as? TemplateParseError, .nestedTag(offset: 0))
        }
    }

    func test_clipboardWithArg_throws() {
        XCTAssertThrowsError(try TemplateParser.parse("{{clipboard:x}}")) { error in
            XCTAssertEqual(error as? TemplateParseError, .unexpectedArgument("clipboard", offset: 0))
        }
    }

    func test_errorOffsetIsCountedInCharacters() {
        // "日本" is 2 characters even though it is 6 UTF-8 bytes.
        XCTAssertThrowsError(try TemplateParser.parse("日本{{nope}}")) { error in
            XCTAssertEqual(error as? TemplateParseError, .unknownName("nope", offset: 2))
        }
    }

    // MARK: - Error presentation

    func test_errorsHaveHumanReadableDescriptions() {
        let errors: [TemplateParseError] = [
            .unclosedTag(offset: 0),
            .emptyTag(offset: 0),
            .nestedTag(offset: 0),
            .unknownName("x", offset: 0),
            .unknownModifier("y", offset: 0),
            .unexpectedArgument("clipboard", offset: 0),
        ]
        for error in errors {
            XCTAssertFalse(error.localizedDescription.isEmpty)
            XCTAssertFalse(error.message.isEmpty)
        }
    }
}
