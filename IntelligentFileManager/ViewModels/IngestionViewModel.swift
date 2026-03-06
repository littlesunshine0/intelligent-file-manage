import Foundation

@MainActor
class IngestionViewModel: ObservableObject {
    @Published var isIngesting: Bool = false
    @Published var progress: Double = 0.0
    @Published var ingestedFiles: [ManagedFile] = []
    @Published var errorMessage: String? = nil
    @Published var selectedDirectory: URL? = nil

    var fileRepository: DefaultFileRepository
    var jsonPipelineService: JSONResourcePipelineService
    var databaseService: DatabaseService
    var settingsService: SettingsService
    var mlOperationService: MLOperationService
    var offlineAssistantService: OfflineAssistantContextService

    init(
        fileRepository: DefaultFileRepository,
        jsonPipelineService: JSONResourcePipelineService,
        databaseService: DatabaseService,
        settingsService: SettingsService,
        mlOperationService: MLOperationService,
        offlineAssistantService: OfflineAssistantContextService
    ) {
        self.fileRepository = fileRepository
        self.jsonPipelineService = jsonPipelineService
        self.databaseService = databaseService
        self.settingsService = settingsService
        self.mlOperationService = mlOperationService
        self.offlineAssistantService = offlineAssistantService
    }

    // MARK: - Directory Ingestion

    func ingestDirectory(_ url: URL) async {
        isIngesting = true
        progress = 0.0
        defer {
            isIngesting = false
            progress = 1.0
        }
        do {
            selectedDirectory = url
            let files = try await fileRepository.scanDirectory(url)
            progress = 0.5
            databaseService.insertMany(files)
            progress = 1.0
            ingestedFiles = databaseService.fetchFiles()
            AppLogger.info("Ingested \(files.count) files from \(url.lastPathComponent)", category: "Ingestion")

            // Auto-classify files when the setting is enabled.
            if settingsService.autoClassifyEnabled && !files.isEmpty {
                AppLogger.info("Auto-classify enabled; classifying \(files.count) files", category: "Ingestion")
                do {
                    try await mlOperationService.processFiles(files)
                } catch {
                    AppLogger.warning("Auto-classify after directory ingestion failed: \(error.localizedDescription)", category: "Ingestion")
                }
                ingestedFiles = databaseService.fetchFiles()
            }
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error("ingestDirectory failed: \(error.localizedDescription)", category: "Ingestion")
        }
    }

    // MARK: - JSON Ingestion

    func ingestJSONFile(_ url: URL) async {
        isIngesting = true
        defer { isIngesting = false }
        do {
            let json = try await jsonPipelineService.extractResources(from: url)

            // Persist conversation threads found in the JSON manifest.
            let conversations = jsonPipelineService.parseConversationData(from: json)
            databaseService.insertMany(conversations)
            if !conversations.isEmpty {
                offlineAssistantService.invalidateCache()
                AppLogger.info("Ingested \(conversations.count) conversation(s) from JSON", category: "Ingestion")
            }

            // Persist file records from the manifest.
            let files = try await jsonPipelineService.processIngestionManifest(json)
            databaseService.insertMany(files)
            ingestedFiles = databaseService.fetchFiles()
            AppLogger.info("Ingested \(files.count) files from JSON manifest", category: "Ingestion")

            // Auto-classify files when the setting is enabled.
            if settingsService.autoClassifyEnabled && !files.isEmpty {
                do {
                    try await mlOperationService.processFiles(files)
                } catch {
                    AppLogger.warning("Auto-classify after JSON ingestion failed: \(error.localizedDescription)", category: "Ingestion")
                }
                ingestedFiles = databaseService.fetchFiles()
            }
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error("ingestJSONFile failed: \(error.localizedDescription)", category: "Ingestion")
        }
    }
}
