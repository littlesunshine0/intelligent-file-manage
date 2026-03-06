import SwiftUI
import SwiftData

@main
struct IntelligentFileManagerApp: App {
    private let modelContainer: ModelContainer
    @StateObject private var appEnvironment: AppEnvironment

    init() {
        do {
            let container = try ModelContainerProvider.shared()
            modelContainer = container
            _appEnvironment = StateObject(wrappedValue: AppEnvironment(modelContainer: container))
        } catch {
            AppLogger.error("Failed to create ModelContainer: \(error.localizedDescription)", category: "App")
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appEnvironment)
        }
        .modelContainer(modelContainer)
    }
}
