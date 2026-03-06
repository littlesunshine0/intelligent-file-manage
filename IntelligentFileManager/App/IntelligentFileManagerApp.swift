import SwiftUI
import SwiftData

@main
struct IntelligentFileManagerApp: App {
    private let modelContainer: ModelContainer
    @StateObject private var appEnvironment: AppEnvironment

    init() {
        let container = (try? ModelContainerProvider.shared()) ?? {
            fatalError("Failed to create ModelContainer.")
        }()
        modelContainer = container
        _appEnvironment = StateObject(wrappedValue: AppEnvironment(modelContainer: container))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appEnvironment)
        }
        .modelContainer(modelContainer)
    }
}
