import SwiftUI
import SwiftData

enum NavigationItem: String, CaseIterable, Identifiable {
    case files = "Files"
    case ingestion = "Ingestion"
    case manifest = "Manifest & Normalize"
    case mlOperations = "ML Operations"
    case codeAnalysis = "Code Analysis"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .files: return "folder"
        case .ingestion: return "tray.and.arrow.down"
        case .manifest: return "list.bullet.clipboard"
        case .mlOperations: return "sparkles"
        case .codeAnalysis: return "chevron.left.forwardslash.chevron.right"
        case .settings: return "gear"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @State private var selectedItem: NavigationItem? = .files
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        ZStack {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                List(selection: $selectedItem) {
                    Section("File Management") {
                        NavigationLink(value: NavigationItem.files) {
                            Label(NavigationItem.files.rawValue, systemImage: NavigationItem.files.icon)
                        }
                        NavigationLink(value: NavigationItem.ingestion) {
                            Label(NavigationItem.ingestion.rawValue, systemImage: NavigationItem.ingestion.icon)
                        }
                    }

                    Section("Analysis") {
                        NavigationLink(value: NavigationItem.manifest) {
                            Label(NavigationItem.manifest.rawValue, systemImage: NavigationItem.manifest.icon)
                        }
                        NavigationLink(value: NavigationItem.mlOperations) {
                            Label(NavigationItem.mlOperations.rawValue, systemImage: NavigationItem.mlOperations.icon)
                        }
                        NavigationLink(value: NavigationItem.codeAnalysis) {
                            Label(NavigationItem.codeAnalysis.rawValue, systemImage: NavigationItem.codeAnalysis.icon)
                        }
                    }

                    Section("Settings") {
                        NavigationLink(value: NavigationItem.settings) {
                            Label(NavigationItem.settings.rawValue, systemImage: NavigationItem.settings.icon)
                        }
                    }
                }
                .navigationTitle("Intelligent File Manager")
#if os(iOS)
                .navigationBarTitleDisplayMode(.large)
#endif
            } detail: {
                NavigationStack {
                    detailView(for: selectedItem)
                }
            }

            // Floating chat overlay (shown everywhere except settings)
            if selectedItem != .settings {
                FloatingChatHistoryView()
                    .ignoresSafeArea()
            }
        }
    }

    @ViewBuilder
    private func detailView(for item: NavigationItem?) -> some View {
        switch item {
        case .files, .none:
            FileExplorerView(appEnvironment: appEnvironment)
        case .ingestion:
            IngestionView(appEnvironment: appEnvironment)
        case .manifest:
            ManifestFeatureView(appEnvironment: appEnvironment)
        case .mlOperations:
            MLOperationsView(appEnvironment: appEnvironment)
        case .codeAnalysis:
            CodeIntelligenceView(appEnvironment: appEnvironment)
        case .settings:
            SettingsView(appEnvironment: appEnvironment)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppEnvironment(modelContainer: try! ModelContainerProvider.preview()))
}
