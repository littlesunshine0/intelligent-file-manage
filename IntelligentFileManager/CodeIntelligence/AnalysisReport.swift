import Foundation

// MARK: - AnalysisReport

struct AnalysisReport: Identifiable {
    var id: UUID
    var projectPath: String
    var timestamp: Date
    var issues: [CodeIssue]
    var metrics: CodeMetrics
    var summary: String

    init(
        id: UUID = UUID(),
        projectPath: String,
        timestamp: Date = Date(),
        issues: [CodeIssue] = [],
        metrics: CodeMetrics = CodeMetrics(),
        summary: String = ""
    ) {
        self.id = id
        self.projectPath = projectPath
        self.timestamp = timestamp
        self.issues = issues
        self.metrics = metrics
        self.summary = summary
    }
}

// MARK: - CodeIssue

struct CodeIssue: Identifiable {
    var id: UUID
    var severity: IssueSeverity
    var message: String
    var filePath: String
    var lineNumber: Int?
    var ruleId: String

    init(
        id: UUID = UUID(),
        severity: IssueSeverity,
        message: String,
        filePath: String,
        lineNumber: Int? = nil,
        ruleId: String = ""
    ) {
        self.id = id
        self.severity = severity
        self.message = message
        self.filePath = filePath
        self.lineNumber = lineNumber
        self.ruleId = ruleId
    }
}

// MARK: - IssueSeverity

enum IssueSeverity: String, CaseIterable {
    case error = "error"
    case warning = "warning"
    case info = "info"

    var displayName: String { rawValue.capitalized }
}

// MARK: - CodeMetrics

struct CodeMetrics {
    var totalFiles: Int
    var linesOfCode: Int
    var complexity: Double
    var testCoverage: Double?

    init(
        totalFiles: Int = 0,
        linesOfCode: Int = 0,
        complexity: Double = 0.0,
        testCoverage: Double? = nil
    ) {
        self.totalFiles = totalFiles
        self.linesOfCode = linesOfCode
        self.complexity = complexity
        self.testCoverage = testCoverage
    }
}
