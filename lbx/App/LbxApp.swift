import SwiftData
import SwiftUI

@main
struct LbxApp: App {
    @State private var promptProvider: UIPromptProvider
    @State private var runner: ActionRunner

    init() {
        let provider = UIPromptProvider()
        _promptProvider = State(initialValue: provider)
        _runner = State(initialValue: ActionRunner(promptProvider: provider))
    }

    var body: some Scene {
        WindowGroup {
            HomeGridView()
                .environment(runner)
                .environment(promptProvider)
        }
        .modelContainer(for: LaunchItem.self)
    }
}
