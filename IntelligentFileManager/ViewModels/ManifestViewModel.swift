import Foundation

@MainActor
class ManifestViewModel: ObservableObject {
    @Published var manifests: [ActionStep] = []
    @Published var isNormalizing: Bool = false
    @Published var normalizedFiles: [ManagedFile] = []

    var databaseService: DatabaseService
    var jsonPipelineService: JSONResourcePipelineService

    init(databaseService: DatabaseService, jsonPipelineService: JSONResourcePipelineService) {
        self.databaseService = databaseService
        self.jsonPipelineService = jsonPipelineService
    }

    // MARK: - Load

    func loadManifests() async {
        manifests = databaseService.fetchActionSteps()
    }

    // MARK: - Normalize

    func normalizeFiles() async {
        isNormalizing = true
        defer { isNormalizing = false }

        let allFiles = databaseService.fetchFiles()
        let step = ActionStep(operationType: "normalization", status: "running")
        databaseService.insert(step)

        var normalized: [ManagedFile] = []
        for file in allFiles {
            // Normalize: trim whitespace from name, lowercase extension
            file.name = file.name.trimmingCharacters(in: .whitespacesAndNewlines)
            file.fileExtension = file.fileExtension.lowercased()
            if file.classificationLabel == nil {
                file.classificationLabel = "Other"
                file.classificationConfidence = 0.5
            }
            normalized.append(file)
        }
        databaseService.save()
        normalizedFiles = normalized

        step.status = "completed"
        step.completedAt = Date()
        databaseService.save()
        manifests = databaseService.fetchActionSteps()
        AppLogger.info("Normalized \(normalized.count) files", category: "Manifest")
    }
}
