import Foundation

@MainActor
class CodeIntelligenceViewModel: ObservableObject {
    @Published var analysisResults: [AnalysisReport] = []
    @Published var isAnalyzing: Bool = false
    @Published var selectedProjectPath: URL? = nil
    @Published var errorMessage: String? = nil

    var orchestrator: CodeIntelligenceOrchestrator

    init(orchestrator: CodeIntelligenceOrchestrator) {
        self.orchestrator = orchestrator
    }

    // MARK: - Analysis

    func analyzeProject(at path: URL) async {
        isAnalyzing = true
        selectedProjectPath = path
        defer { isAnalyzing = false }
        do {
            let report = try await orchestrator.analyzeProject(at: path)
            analysisResults.insert(report, at: 0)
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error("analyzeProject failed: \(error.localizedDescription)", category: "CodeIntelligence")
        }
    }

    // MARK: - Load

    func loadResults() async {
        analysisResults = orchestrator.reports
    }
}
