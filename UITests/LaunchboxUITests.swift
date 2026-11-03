import XCTest

/// End-to-end checks for the manual test checklist in README.md, run against
/// a fresh in-memory store seeded with the sample actions.
final class LaunchboxUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        XCTAssertTrue(button("tile.Google Search").waitForExistence(timeout: 15), "Seeded actions should appear")
    }

    // MARK: - Helpers

    /// Any element with this identifier. Prefer `button(_:)` for buttons: an
    /// untyped query can match a wrapper (e.g. a toolbar item) instead.
    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func button(_ identifier: String) -> XCUIElement {
        app.buttons.matching(identifier: identifier).firstMatch
    }

    /// Taps a toolbar item by coordinate. On recent iOS, XCUITest's regular tap
    /// first asks the toolbar item to scroll itself visible, which fails for
    /// toolbar menus (kAXErrorCannotComplete) even though the item is on screen.
    private func tapToolbarItem(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        let item = button(identifier)
        XCTAssertTrue(item.waitForExistence(timeout: 10), "\(identifier) should exist", file: file, line: line)
        item.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    private func waitUntil(
        _ element: XCUIElement,
        isEnabled: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let predicate = NSPredicate(format: "exists == true AND isEnabled == %@", NSNumber(value: isEnabled))
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: 5)
        XCTAssertEqual(result, .completed, "Expected isEnabled == \(isEnabled)", file: file, line: line)
    }

    private func assertSafariOpens(file: StaticString = #filePath, line: UInt = #line) {
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        XCTAssertTrue(safari.wait(for: .runningForeground, timeout: 30), "Safari should open", file: file, line: line)

        // Come back to Launchbox: it must still be usable after launching another app, and
        // leaving it in the foreground lets the next test's launch() terminate it cleanly.
        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15), "Launchbox should come back", file: file, line: line)
        XCTAssertTrue(
            button("tile.Google Search").waitForExistence(timeout: 10),
            "The grid should be usable after returning",
            file: file, line: line
        )
    }

    private func type(_ text: String, into identifier: String) {
        let field = element(identifier)
        XCTAssertTrue(field.waitForExistence(timeout: 5), "\(identifier) should exist")
        field.tap()
        field.typeText(text)
    }

    private func startNewItem(_ menuTitle: String) {
        tapToolbarItem("home.add")
        let item = app.buttons[menuTitle].firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 5))
        item.tap()
    }

    // MARK: - Checklist

    /// Checklist 1: a static https URL opens Safari.
    func test_staticURLAction_opensSafari() {
        button("tile.Example").tap()
        assertSafariOpens()
    }

    /// Checklist 3: a prompt is shown and the URL opens after input.
    func test_promptAction_asksForInputThenOpensSafari() {
        button("tile.Google Search").tap()
        type("swift ui", into: "prompt.field")
        tapToolbarItem("prompt.submit")
        assertSafariOpens()
    }

    /// Checklist 4: an unhandled scheme shows an error instead of crashing.
    /// Also covers creating an action in the editor.
    func test_unknownScheme_showsErrorToast() {
        startNewItem("New Action")
        type("Broken", into: "editor.name")
        type("zzzz-not-installed://", into: "editor.template")
        tapToolbarItem("editor.save")

        let tile = button("tile.Broken")
        XCTAssertTrue(tile.waitForExistence(timeout: 5))
        tile.tap()

        let toast = element("toast.message")
        XCTAssertTrue(toast.waitForExistence(timeout: 10), "An error toast should appear")
        XCTAssertTrue(toast.label.hasPrefix("Couldn't open"), toast.label)
        XCTAssertEqual(app.state, .runningForeground)
    }

    /// Checklist 5: cancelling a prompt opens nothing, and the runner is usable again.
    func test_cancellingPrompt_opensNothing() {
        button("tile.Google Search").tap()
        let field = element("prompt.field")
        XCTAssertTrue(field.waitForExistence(timeout: 5))

        tapToolbarItem("prompt.cancel")
        XCTAssertTrue(field.waitForNonExistence(timeout: 5))
        XCTAssertEqual(app.state, .runningForeground)

        // A cancelled run must not leave the runner stuck.
        button("tile.Google Search").tap()
        XCTAssertTrue(element("prompt.field").waitForExistence(timeout: 5))
    }

    /// Checklist 6: actions inside a group run from the overlay.
    func test_groupOverlay_runsChildActionWithPrompt() {
        button("tile.Lookup").tap()
        let child = button("tile.Wikipedia")
        XCTAssertTrue(child.waitForExistence(timeout: 5))
        child.tap()

        type("Launch Center", into: "prompt.field")
        tapToolbarItem("prompt.submit")
        assertSafariOpens()
    }

    /// Checklist 6: create a group and assign a new action to it.
    func test_newActionCanBeAssignedToNewGroup() {
        startNewItem("New Group")
        type("Work", into: "editor.name")
        tapToolbarItem("editor.save")
        XCTAssertTrue(button("tile.Work").waitForExistence(timeout: 5))

        startNewItem("New Action")
        type("Site", into: "editor.name")
        type("https://example.com", into: "editor.template")
        element("editor.group").tap()
        let option = app.buttons["Work"].firstMatch
        XCTAssertTrue(option.waitForExistence(timeout: 5))
        option.tap()
        tapToolbarItem("editor.save")

        XCTAssertFalse(button("tile.Site").waitForExistence(timeout: 2), "Site should not be at the root")
        button("tile.Work").tap()
        XCTAssertTrue(button("tile.Site").waitForExistence(timeout: 5), "Site should be inside Work")
    }

    /// Save-time validation: malformed templates cannot be saved.
    func test_invalidTemplate_isReportedAndCannotBeSaved() {
        startNewItem("New Action")
        type("Bad", into: "editor.name")
        type("example.com", into: "editor.template")

        XCTAssertTrue(element("editor.issue").waitForExistence(timeout: 5))
        waitUntil(button("editor.save"), isEnabled: false)

        let template = element("editor.template")
        template.typeText("/{{promt}}")
        let issue = element("editor.issue")
        XCTAssertTrue(issue.waitForExistence(timeout: 5))
        XCTAssertTrue(issue.label.contains("promt"), issue.label)
        waitUntil(button("editor.save"), isEnabled: false)

        // Fixing the template enables Save.
        template.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "example.com/{{promt}}".count))
        template.typeText("https://example.com")
        waitUntil(button("editor.save"), isEnabled: true)
    }

    /// Context menu: duplicate, then delete with confirmation.
    func test_contextMenu_duplicatesAndDeletes() {
        button("tile.Example").press(forDuration: 1.2)
        let duplicate = app.buttons["Duplicate"].firstMatch
        XCTAssertTrue(duplicate.waitForExistence(timeout: 5))
        duplicate.tap()

        let copy = button("tile.Example Copy")
        XCTAssertTrue(copy.waitForExistence(timeout: 5))

        copy.press(forDuration: 1.2)
        let delete = app.buttons["Delete"].firstMatch
        XCTAssertTrue(delete.waitForExistence(timeout: 5))
        delete.tap()

        // Confirmation dialog.
        let confirm = app.buttons["Delete"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()

        XCTAssertTrue(copy.waitForNonExistence(timeout: 5))
        XCTAssertTrue(button("tile.Example").exists)
    }
}
