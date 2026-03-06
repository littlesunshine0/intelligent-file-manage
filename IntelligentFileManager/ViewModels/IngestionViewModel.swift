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

    init(
        fileRepository: DefaultFileRepository,
        jsonPipelineService: JSONResourcePipelineService,
        databaseService: DatabaseService
    ) {
        self.fileRepository = fileRepository
        self.jsonPipelineService = jsonPipelineService
        self.databaseService = databaseService
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
            let total = Double(files.count)
            for (index, file) in files.enumerated() {
                databaseService.insert(file)
                progress = total > 0 ? Double(index + 1) / total : 1.0
            }
            ingestedFiles = databaseService.fetchFiles()
            AppLogger.info("Ingested \(files.count) files from \(url.lastPathComponent)", category: "Ingestion")
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
            let files = try await jsonPipelineService.processIngestionManifest(json)
            for file in files {
                databaseService.insert(file)
            }
            ingestedFiles = databaseService.fetchFiles()
            AppLogger.info("Ingested \(files.count) files from JSON manifest", category: "Ingestion")
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error("ingestJSONFile failed: \(error.localizedDescription)", category: "Ingestion")
        }
    }
}
