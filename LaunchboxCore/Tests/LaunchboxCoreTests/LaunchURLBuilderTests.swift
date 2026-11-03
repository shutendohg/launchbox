import XCTest
@testable import LaunchboxCore

final class LaunchURLBuilderTests: XCTestCase {

    // MARK: - Valid

    func test_httpsURL_isBuilt() throws {
        let url = try LaunchURLBuilder.build("https://example.com/path?q=1")
        XCTAssertEqual(url.absoluteString, "https://example.com/path?q=1")
        XCTAssertEqual(url.scheme, "https")
    }

    func test_schemeOnlyURL_isBuilt() throws {
        XCTAssertEqual(try LaunchURLBuilder.build("sms:").absoluteString, "sms:")
    }

    func test_opaqueURL_isBuilt() throws {
        XCTAssertEqual(try LaunchURLBuilder.build("tel:0312345678").absoluteString, "tel:0312345678")
    }

    func test_customSchemeWithPlusDashDot_isBuilt() throws {
        let url = try LaunchURLBuilder.build("x-my.app+v2://open")
        XCTAssertEqual(url.scheme, "x-my.app+v2")
    }

    func test_unknownButWellFormedScheme_isBuilt() throws {
        // Whether an app handles the scheme is only known when opening it.
        XCTAssertEqual(
            try LaunchURLBuilder.build("zzzz-not-installed://").absoluteString,
            "zzzz-not-installed://"
        )
    }

    func test_percentEncodedTemplateOutput_isPreserved() throws {
        let string = "shortcuts://run-shortcut?name=My%20Shortcut"
        XCTAssertEqual(try LaunchURLBuilder.build(string).absoluteString, string)
    }

    func test_surroundingWhitespace_isTrimmed() throws {
        XCTAssertEqual(try LaunchURLBuilder.build("  https://a.com \n").absoluteString, "https://a.com")
    }

    func test_nonAsciiCharacters_arePercentEncoded() throws {
        XCTAssertEqual(
            try LaunchURLBuilder.build("https://a.com/?q=日本").absoluteString,
            "https://a.com/?q=%E6%97%A5%E6%9C%AC"
        )
    }

    // MARK: - Invalid

    func test_emptyString_throwsEmpty() {
        XCTAssertThrowsError(try LaunchURLBuilder.build("")) {
            XCTAssertEqual($0 as? LaunchURLError, .empty)
        }
    }

    func test_whitespaceOnly_throwsEmpty() {
        XCTAssertThrowsError(try LaunchURLBuilder.build("  \n")) {
            XCTAssertEqual($0 as? LaunchURLError, .empty)
        }
    }

    func test_missingScheme_throws() {
        XCTAssertThrowsError(try LaunchURLBuilder.build("example.com/path")) {
            XCTAssertEqual($0 as? LaunchURLError, .missingScheme)
        }
    }

    func test_emptyScheme_throws() {
        XCTAssertThrowsError(try LaunchURLBuilder.build("://x")) {
            XCTAssertEqual($0 as? LaunchURLError, .missingScheme)
        }
    }

    func test_schemeStartingWithDigit_throwsInvalidScheme() {
        XCTAssertThrowsError(try LaunchURLBuilder.build("1app://x")) {
            XCTAssertEqual($0 as? LaunchURLError, .invalidScheme("1app"))
        }
    }

    func test_schemeWithIllegalCharacter_throwsInvalidScheme() {
        XCTAssertThrowsError(try LaunchURLBuilder.build("my_app://x")) {
            XCTAssertEqual($0 as? LaunchURLError, .invalidScheme("my_app"))
        }
    }

    func test_innerWhitespace_throws() {
        XCTAssertThrowsError(try LaunchURLBuilder.build("https://a.com/?q=a b")) {
            XCTAssertEqual($0 as? LaunchURLError, .containsWhitespace)
        }
    }

    func test_errorsHaveMessages() {
        let errors: [LaunchURLError] = [
            .empty, .missingScheme, .invalidScheme("x"), .containsWhitespace, .malformed("x"),
        ]
        for error in errors {
            XCTAssertFalse(error.localizedDescription.isEmpty)
        }
    }
}
