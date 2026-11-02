import Foundation

/// An sRGB color parsed from a `#RRGGBB` string. UI-independent so it can be
/// validated and tested in LbxCore; the app maps it to SwiftUI `Color`.
public struct HexColor: Hashable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    /// Accepts `#RRGGBB` or `RRGGBB` (case-insensitive).
    public init?(_ string: String) {
        var hex = string.trimmingCharacters(in: .whitespaces)
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6,
              hex.allSatisfy(\.isHexDigit),
              let value = UInt32(hex, radix: 16)
        else { return nil }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    /// The fixed palette offered by the editor.
    public static let palette: [String] = [
        "#FF3B30", // red
        "#FF9500", // orange
        "#FFCC00", // yellow
        "#34C759", // green
        "#00C7BE", // mint
        "#30B0C7", // teal
        "#32ADE6", // cyan
        "#007AFF", // blue
        "#5856D6", // indigo
        "#AF52DE", // purple
        "#FF2D55", // pink
        "#A2845E", // brown
        "#8E8E93", // gray
        "#1C1C1E", // graphite
    ]

    public static let defaultHex = "#007AFF"
}
