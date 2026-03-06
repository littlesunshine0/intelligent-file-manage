import Foundation

@MainActor
class CodeIntelligenceOrchestrator: ObservableObject {
    @Published var reports: [AnalysisReport] = []
    @Published var isAnalyzing: Bool = false

    // MARK: - Project Analysis

    func analyzeProject(at url: URL) async throws -> AnalysisReport {
        isAnalyzing = true
        defer { isAnalyzing = false }

        AppLogger.info("Starting analysis of project at \(url.lastPathComponent)", category: "CodeIntelligence")

        let fileURLs = collectSourceFiles(at: url)
        let issues = try await analyzeFiles(fileURLs)
        let metrics = await calculateMetrics(for: fileURLs)

        let errorCount = issues.filter { $0.severity == .error }.count
        let warningCount = issues.filter { $0.severity == .warning }.count
        let summary = "Found \(issues.count) issues (\(errorCount) errors, \(warningCount) warnings) " +
                      "across \(metrics.totalFiles) files (\(metrics.linesOfCode) LOC)."

        let report = AnalysisReport(
            projectPath: url.path,
            issues: issues,
            metrics: metrics,
            summary: summary
        )
        reports.insert(report, at: 0)
        AppLogger.info("Analysis complete: \(summary)", category: "CodeIntelligence")
        return report
    }

    // MARK: - File Analysis

    func analyzeFile(_ url: URL) async throws -> [CodeIssue] {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }
        return lintContent(content, filePath: url.path)
    }

    // MARK: - Metrics

    private static let complexityKeywords = ["if ", "else ", "for ", "while ", "guard ", "switch ", "catch "]

    private func calculateMetrics(for files: [URL]) async -> CodeMetrics {
        var totalLOC = 0
        var totalComplexity = 0.0

        for fileURL in files {
            if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
                let lines = content.components(separatedBy: .newlines)
                totalLOC += lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
                // Rough cyclomatic complexity estimate
                for keyword in Self.complexityKeywords {
                    totalComplexity += Double(content.components(separatedBy: keyword).count - 1)
                }
            }
        }
        return CodeMetrics(
            totalFiles: files.count,
            linesOfCode: totalLOC,
            complexity: totalComplexity / max(1.0, Double(files.count))
        )
    }

    // MARK: - Private Helpers

    private func collectSourceFiles(at url: URL) -> [URL] {
        let fm = FileManager.default
        let extensions = Set(["swift", "py", "js", "ts", "java", "kt", "cpp", "c", "h", "rb", "go"])
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }

        return enumerator.compactMap { element -> URL? in
            guard let fileURL = element as? URL,
                  extensions.contains(fileURL.pathExtension.lowercased()) else { return nil }
            return fileURL
        }
    }

    private func analyzeFiles(_ files: [URL]) async throws -> [CodeIssue] {
        var allIssues: [CodeIssue] = []
        for file in files {
            let issues = try await analyzeFile(file)
            allIssues.append(contentsOf: issues)
        }
        return allIssues
    }

    private func lintContent(_ content: String, filePath: String) -> [CodeIssue] {
        var issues: [CodeIssue] = []
        let lines = content.components(separatedBy: .newlines)
        for (index, line) in lines.enumerated() {
            let lineNum = index + 1
            if line.count > 120 {
                issues.append(CodeIssue(
                    severity: .warning,
                    message: "Line exceeds 120 characters (\(line.count))",
                    filePath: filePath,
                    lineNumber: lineNum,
                    ruleId: "line-length"
                ))
            }
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("TODO:") || trimmed.hasPrefix("FIXME:") {
                issues.append(CodeIssue(
                    severity: .info,
                    message: "Unresolved marker: \(trimmed)",
                    filePath: filePath,
                    lineNumber: lineNum,
                    ruleId: "todo-marker"
                ))
            }
            if trimmed.hasPrefix("//") && trimmed.contains("force unwrap") {
                issues.append(CodeIssue(
                    severity: .warning,
                    message: "Avoid force unwrapping",
                    filePath: filePath,
                    lineNumber: lineNum,
                    ruleId: "force-unwrap"
                ))
            }
        }
        return issues
    }
}
