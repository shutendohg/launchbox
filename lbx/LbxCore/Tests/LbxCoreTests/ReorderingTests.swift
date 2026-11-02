import XCTest
@testable import LbxCore

final class ReorderingTests: XCTestCase {

    func test_movingForward_placesItemAfterTarget() {
        XCTAssertEqual(Reordering.move("a", onto: "c", in: ["a", "b", "c", "d"]), ["b", "c", "a", "d"])
    }

    func test_movingBackward_placesItemBeforeTarget() {
        XCTAssertEqual(Reordering.move("d", onto: "b", in: ["a", "b", "c", "d"]), ["a", "d", "b", "c"])
    }

    func test_movingToLast_works() {
        XCTAssertEqual(Reordering.move("a", onto: "d", in: ["a", "b", "c", "d"]), ["b", "c", "d", "a"])
    }

    func test_movingToFirst_works() {
        XCTAssertEqual(Reordering.move("c", onto: "a", in: ["a", "b", "c"]), ["c", "a", "b"])
    }

    func test_droppingOnItself_isNoOp() {
        XCTAssertEqual(Reordering.move("b", onto: "b", in: ["a", "b", "c"]), ["a", "b", "c"])
    }

    func test_unknownIDs_areNoOp() {
        XCTAssertEqual(Reordering.move("x", onto: "a", in: ["a", "b"]), ["a", "b"])
        XCTAssertEqual(Reordering.move("a", onto: "x", in: ["a", "b"]), ["a", "b"])
    }
}

final class TemplateLinterTests: XCTestCase {

    func test_validTemplates_haveNoIssue() {
        XCTAssertNil(TemplateLinter.issue(in: "sms:"))
        XCTAssertNil(TemplateLinter.issue(in: "https://g.com/?q={{prompt:Q}}"))
        XCTAssertNil(TemplateLinter.issue(in: "x-app://{{date:HH:mm}}"))
    }

    func test_parseError_isReported() {
        XCTAssertEqual(
            TemplateLinter.issue(in: "https://g.com/?q={{promt}}"),
            .parse(.unknownName("promt", offset: 17))
        )
    }

    func test_missingScheme_isReported() {
        XCTAssertEqual(TemplateLinter.issue(in: "example.com"), .url(.missingScheme))
    }

    func test_emptyTemplate_isReported() {
        XCTAssertEqual(TemplateLinter.issue(in: ""), .url(.empty))
    }

    func test_literalWhitespace_isReported() {
        XCTAssertEqual(TemplateLinter.issue(in: "https://a.com/?q=a b"), .url(.containsWhitespace))
    }

    func test_templateBeginningWithRawTag_isNotFlaggedForScheme() {
        // The scheme comes from run-time input, so it cannot be checked statically.
        XCTAssertNil(TemplateLinter.issue(in: "{{clipboard|raw}}"))
    }

    func test_issueMessagesAreNotEmpty() {
        XCTAssertFalse(TemplateIssue.parse(.emptyTag(offset: 0)).message.isEmpty)
        XCTAssertFalse(TemplateIssue.url(.missingScheme).message.isEmpty)
    }

    func test_variables_describeTagsInOrder() throws {
        XCTAssertEqual(
            try TemplateLinter.variables(in: "{{prompt:To}}{{clipboard|raw}}{{date}}"),
            [
                TemplateVariable(name: .prompt, detail: "To", isRaw: false),
                TemplateVariable(name: .clipboard, detail: nil, isRaw: true),
                TemplateVariable(name: .date, detail: "yyyy-MM-dd", isRaw: false),
            ]
        )
    }
}
