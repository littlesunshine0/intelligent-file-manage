import Foundation

// Carries enough information to display a single classification result in the UI.
struct ClassificationResult: Identifiable {
    let id: UUID
    let fileName: String
    let label: String
}

@MainActor
class MLOperationsViewModel: ObservableObject {
    @Published var operations: [ActionStep] = []
    @Published var isProcessing: Bool = false
    @Published var classificationResults: [ClassificationResult] = []
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
                classificationResults.append(ClassificationResult(id: file.id, fileName: file.name, label: label))
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
        classificationResults = []
        errorMessage = nil
    }
}
