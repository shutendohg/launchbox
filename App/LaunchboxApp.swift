import SwiftData
import SwiftUI

@main
struct LaunchboxApp: App {
    /// Set by UI tests: use a throwaway in-memory store and always seed it.
    static let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")

    @State private var promptProvider: UIPromptProvider
    @State private var runner: ActionRunner
    /// Created once; `body` may be evaluated many times.
    private let modelContainer: ModelContainer

    init() {
        let provider = UIPromptProvider()
        _promptProvider = State(initialValue: provider)
        _runner = State(initialValue: ActionRunner(promptProvider: provider))
        modelContainer = Self.makeModelContainer()
    }

    var body: some Scene {
        WindowGroup {
            HomeGridView()
                .environment(runner)
                .environment(promptProvider)
        }
        .modelContainer(modelContainer)
    }

    private static func makeModelContainer() -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: isUITesting)
        do {
            return try ModelContainer(for: LaunchItem.self, configurations: configuration)
        } catch {
            fatalError("Failed to create the model container: \(error)")
        }
    }
}
