import XCTest
@testable import LbxCore

private struct FixedAnswerProvider: PromptProviding {
    func prompt(label: String) async -> String? { "test value" }
}

private struct FixedContext: ResolutionContext {
    var promptProvider: any PromptProviding = FixedAnswerProvider()
    var clipboardText = "clip board"
    var now = Date(timeIntervalSince1970: 0)
}

final class ActionPresetTests: XCTestCase {

    func test_thereAreAboutTenPresets() {
        XCTAssertGreaterThanOrEqual(ActionPreset.all.count, 10)
    }

    func test_presetIDsAreUnique() {
        let ids = ActionPreset.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func test_everyPresetTemplateParses() {
        for preset in ActionPreset.all {
            XCTAssertNoThrow(try TemplateParser.parse(preset.urlTemplate), preset.id)
        }
    }

    func test_everyPresetResolvesToAValidURL() async throws {
        for preset in ActionPreset.all {
            let resolved = try await TemplateResolver.resolve(preset.urlTemplate, context: FixedContext())
            XCTAssertNoThrow(try LaunchURLBuilder.build(resolved), preset.id)
        }
    }

    func test_shortcutsBridgePresetIsIncluded() {
        XCTAssertTrue(ActionPreset.all.contains {
            $0.urlTemplate.hasPrefix("shortcuts://run-shortcut?name=")
        })
    }

    func test_everyPresetHasDisplayFields() {
        for preset in ActionPreset.all {
            XCTAssertFalse(preset.name.isEmpty, preset.id)
            XCTAssertFalse(preset.iconSymbol.isEmpty, preset.id)
            XCTAssertNotNil(HexColor(preset.colorHex), preset.id)
        }
    }
}

final class HexColorTests: XCTestCase {

    func test_parsesSixDigitHexWithOrWithoutHash() {
        XCTAssertEqual(HexColor("#FF8000"), HexColor(red: 1, green: 128.0 / 255, blue: 0))
        XCTAssertEqual(HexColor("ff8000"), HexColor(red: 1, green: 128.0 / 255, blue: 0))
    }

    func test_rejectsMalformedHex() {
        XCTAssertNil(HexColor(""))
        XCTAssertNil(HexColor("#FFF"))
        XCTAssertNil(HexColor("#GGGGGG"))
        XCTAssertNil(HexColor("#FF80001"))
    }

    func test_paletteEntriesAreValidAndUnique() {
        XCTAssertGreaterThanOrEqual(HexColor.palette.count, 12)
        XCTAssertEqual(Set(HexColor.palette).count, HexColor.palette.count)
        for hex in HexColor.palette { XCTAssertNotNil(HexColor(hex), hex) }
    }
}
