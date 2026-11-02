import Foundation

/// A ready-made action template the editor can insert. Presets only reduce
/// typing; lbx cannot discover which schemes installed apps support.
public struct ActionPreset: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let iconSymbol: String
    public let colorHex: String
    public let urlTemplate: String
    /// One-line explanation shown in the preset picker.
    public let summary: String

    public init(id: String, name: String, iconSymbol: String, colorHex: String, urlTemplate: String, summary: String) {
        self.id = id
        self.name = name
        self.iconSymbol = iconSymbol
        self.colorHex = colorHex
        self.urlTemplate = urlTemplate
        self.summary = summary
    }
}

extension ActionPreset {
    public static let all: [ActionPreset] = [
        ActionPreset(
            id: "shortcut",
            name: "Run Shortcut",
            iconSymbol: "square.stack.3d.up.fill",
            colorHex: "#5856D6",
            urlTemplate: "shortcuts://run-shortcut?name={{prompt:Shortcut name}}",
            summary: "Runs a shortcut by name. Use an \"Open App\" shortcut to reach apps without a URL scheme."
        ),
        ActionPreset(
            id: "shortcut-clipboard",
            name: "Shortcut with Clipboard",
            iconSymbol: "doc.on.clipboard.fill",
            colorHex: "#AF52DE",
            urlTemplate: "shortcuts://run-shortcut?name={{prompt:Shortcut name}}&input=clipboard",
            summary: "Runs a shortcut and passes the clipboard as its input."
        ),
        ActionPreset(
            id: "sms",
            name: "New Message",
            iconSymbol: "message.fill",
            colorHex: "#34C759",
            urlTemplate: "sms:{{prompt:Phone number}}",
            summary: "Opens Messages with a new message to a number."
        ),
        ActionPreset(
            id: "tel",
            name: "Call",
            iconSymbol: "phone.fill",
            colorHex: "#34C759",
            urlTemplate: "tel:{{prompt:Phone number}}",
            summary: "Calls a phone number."
        ),
        ActionPreset(
            id: "facetime",
            name: "FaceTime",
            iconSymbol: "video.fill",
            colorHex: "#00C7BE",
            urlTemplate: "facetime:{{prompt:Phone or email}}",
            summary: "Starts a FaceTime call."
        ),
        ActionPreset(
            id: "mailto",
            name: "New Email",
            iconSymbol: "envelope.fill",
            colorHex: "#007AFF",
            urlTemplate: "mailto:{{prompt:To}}?subject={{prompt:Subject}}",
            summary: "Composes an email with a recipient and subject."
        ),
        ActionPreset(
            id: "google",
            name: "Google Search",
            iconSymbol: "magnifyingglass",
            colorHex: "#007AFF",
            urlTemplate: "https://www.google.com/search?q={{prompt:Search}}",
            summary: "Searches Google in Safari."
        ),
        ActionPreset(
            id: "google-clipboard",
            name: "Search Clipboard",
            iconSymbol: "doc.text.magnifyingglass",
            colorHex: "#32ADE6",
            urlTemplate: "https://www.google.com/search?q={{clipboard}}",
            summary: "Searches Google for the clipboard text."
        ),
        ActionPreset(
            id: "wikipedia",
            name: "Wikipedia",
            iconSymbol: "book.fill",
            colorHex: "#8E8E93",
            urlTemplate: "https://en.wikipedia.org/w/index.php?search={{prompt:Search}}",
            summary: "Searches Wikipedia."
        ),
        ActionPreset(
            id: "maps",
            name: "Directions",
            iconSymbol: "map.fill",
            colorHex: "#FF9500",
            urlTemplate: "maps://?daddr={{prompt:Destination}}",
            summary: "Gets directions in Apple Maps."
        ),
        ActionPreset(
            id: "youtube",
            name: "YouTube Search",
            iconSymbol: "play.rectangle.fill",
            colorHex: "#FF3B30",
            urlTemplate: "youtube://results?search_query={{prompt:Search}}",
            summary: "Searches in the YouTube app (requires YouTube)."
        ),
        ActionPreset(
            id: "translate-clipboard",
            name: "Translate Clipboard",
            iconSymbol: "character.bubble.fill",
            colorHex: "#30B0C7",
            urlTemplate: "https://translate.google.com/?sl=auto&tl=en&text={{clipboard}}",
            summary: "Translates the clipboard text with Google Translate."
        ),
        ActionPreset(
            id: "app-store",
            name: "App Store Search",
            iconSymbol: "bag.fill",
            colorHex: "#007AFF",
            urlTemplate: "itms-apps://search.itunes.apple.com/WebObjects/MZSearch.woa/wa/search?media=software&term={{prompt:App name}}",
            summary: "Searches the App Store."
        ),
        ActionPreset(
            id: "calendar",
            name: "Calendar",
            iconSymbol: "calendar",
            colorHex: "#FF3B30",
            urlTemplate: "calshow:",
            summary: "Opens Calendar."
        ),
    ]
}
