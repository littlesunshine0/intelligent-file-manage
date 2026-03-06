import Foundation

@MainActor
class MLOperationsViewModel: ObservableObject {
    @Published var operations: [ActionStep] = []
    @Published var isProcessing: Bool = false
    @Published var classificationResults: [UUID: String] = [:]
    @Published var errorMessage: String? = nil

    var mlOperationService: MLOperationService
    var databaseService: DatabaseService

    init(mlOperationService: MLOperationService, databaseService: DatabaseService) {
        self.mlOperationService = mlOperationService
        self.databaseService = databaseService
    }

    // MARK: - Classification

    func runClassification(on files: [ManagedFile]) async {
        isProcessing = true
        defer { isProcessing = false }
        do {
            for file in files {
                let label = try await mlOperationService.classifyFile(file)
                classificationResults[file.id] = label
            }
            operations = databaseService.fetchActionSteps()
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error("runClassification failed: \(error.localizedDescription)", category: "MLOperations")
        }
    }

    // MARK: - Load

    func loadOperations() async {
        operations = databaseService.fetchActionSteps()
    }

    // MARK: - Clear

    func clearResults() {
        classificationResults = [:]
        errorMessage = nil
    }
}
