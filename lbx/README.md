# lbx

A personal iOS launcher in the spirit of Launch Center Pro: a grid of tiles that
open URL schemes, with variables (text prompts, clipboard, date) filled in at
run time.

- SwiftUI + SwiftData, iOS 17+
- Pure logic lives in the `LbxCore` Swift package and is unit tested
- The Xcode project is generated with XcodeGen from `project.yml`

## Features (MVP)

- 3-column home grid of actions and groups (folders, one level deep)
- Tap an action to run it; tap a group to open it as an overlay
- Long press: Edit / Duplicate / Delete
- Edit mode: drag & drop to reorder (root and each group keep their own order)
- Action editor: name, URL template with inline validation and a variable
  preview, SF Symbol picker (≈100 symbols + any name), 14-color palette,
  group assignment, and presets
- Sample actions are added on first launch

## Build and run

Requirements: Xcode 16 or later and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
```

```bash
cd lbx && xcodegen generate && open Lbx.xcodeproj
```

To run on a device, select your team under *Signing & Capabilities* (a free
Personal Team works, but the signature expires after 7 days) and enable
Developer Mode on the device.

### Tests

```bash
cd lbx/LbxCore && swift test
```

The same tests run from the `Lbx` scheme in Xcode (`⌘U`). CI
(`.github/workflows/lbx.yml`) runs them on Linux and macOS and builds the app
for the iOS Simulator.

## URL templates

```
template   := ( literal | tag )*
tag        := "{{" name ( ":" arg )? ( "|" modifier )* "}}"
name       := "prompt" | "clipboard" | "date"
modifier   := "raw"
```

| Tag | Value |
| --- | --- |
| `{{prompt}}`, `{{prompt:Label}}` | Text typed when the action runs. Several prompts are asked in order. Cancelling aborts the run. |
| `{{clipboard}}` | The clipboard text (empty if none). |
| `{{date}}`, `{{date:HH:mm}}` | The current date/time as a `DateFormatter` pattern (default `yyyy-MM-dd`). |

Values are percent-encoded (`urlQueryAllowed` minus `&=+?#`) unless the tag has
`|raw`, e.g. `{{clipboard|raw}}` to open a copied URL.

Examples:

```
https://www.google.com/search?q={{prompt:Search}}
mailto:{{prompt:To}}?subject={{prompt:Subject}}
shortcuts://run-shortcut?name={{prompt:Shortcut name}}&input=clipboard
{{clipboard|raw}}
```

Templates are checked when you save them: unknown variables, unclosed tags,
missing schemes, and spaces in the literal part are reported in the editor.

## Opening apps without a URL scheme (Shortcuts bridge)

Many apps don't publish a URL scheme. You can still launch them via Shortcuts:

1. In the Shortcuts app, create a shortcut with the **Open App** action and
   pick the app. Give the shortcut a name, e.g. `Open Notes`.
2. In lbx, add an action with the **Run Shortcut** preset and replace the
   prompt with the name: `shortcuts://run-shortcut?name=Open%20Notes`.

Shortcuts briefly appears before switching to the target app.

## Known limitations

- **No app discovery.** iOS has no API to list installed apps or their schemes.
  You need to know (or look up) the scheme; presets only save typing.
- **No pre-check.** lbx never calls `canOpenURL` (it requires declaring every
  scheme in `LSApplicationQueriesSchemes`, capped at 50). It just tries to open
  the URL and shows “Couldn't open: …” if nothing handles it.
- **Universal Links** (`https://` URLs claimed by apps) may open in Safari
  instead of the app, depending on the URL. Prefer the app's custom scheme
  when it has one.
- **No escape syntax.** A literal `{{` cannot be written in a template.
- Launching always brings the target app to the foreground.
- Not yet included: widgets, Siri/App Intents, time/location/NFC triggers,
  import/export, an `lbx://` URL scheme, and iCloud sync.

## Manual test checklist (Simulator)

1. `https://example.com` → Safari opens.
2. `sms:` → Messages compose opens.
3. `https://www.google.com/search?q={{prompt:Query}}` → the prompt appears;
   the input is percent-encoded in Safari's URL.
4. `zzzz-not-installed://` → an error toast appears, no crash.
5. Cancel a prompt → nothing opens.
6. Create a group, add an action to it, and run it from the overlay.
7. Reorder in edit mode, relaunch the app → the order is kept.

On a device, also try real app schemes such as `youtube://`.

## Layout

```
lbx/
├── project.yml            XcodeGen definition (app + LbxCore + tests)
├── LbxCore/               UI-independent logic (SwiftPM, unit tested)
│   └── Sources/LbxCore/
│       ├── Template/      TemplateToken, TemplateParser, TemplateResolver, TemplateLinter
│       ├── LaunchURLBuilder.swift
│       ├── ActionPreset.swift, HexColor.swift, Reordering.swift
└── App/
    ├── LbxApp.swift
    ├── Models/            LaunchItem (SwiftData), LaunchItemStore, SeedData
    ├── Runner/            ActionRunner, UIPromptProvider
    └── Views/             Home grid, group overlay, editor, pickers, prompt sheet, toast
```
