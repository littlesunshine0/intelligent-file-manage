import SwiftUI

struct ReportDetailView: View {
    let report: AnalysisReport

    private var issuesBySeverity: [(IssueSeverity, [CodeIssue])] {
        IssueSeverity.allCases.compactMap { severity in
            let items = report.issues.filter { $0.severity == severity }
            return items.isEmpty ? nil : (severity, items)
        }
    }

    var body: some View {
        List {
            // MARK: Summary
            Section("Summary") {
                Text(report.summary)
                    .font(.callout)
            }

            // MARK: Metrics
            Section("Metrics") {
                MetricRow(label: "Total Files", value: "\(report.metrics.totalFiles)", icon: "doc.on.doc")
                MetricRow(label: "Lines of Code", value: "\(report.metrics.linesOfCode)", icon: "text.alignleft")
                MetricRow(
                    label: "Avg Complexity",
                    value: String(format: "%.1f", report.metrics.complexity),
                    icon: "chart.bar"
                )
                if let coverage = report.metrics.testCoverage {
                    MetricRow(
                        label: "Test Coverage",
                        value: String(format: "%.1f%%", coverage * 100),
                        icon: "checkmark.shield"
                    )
                }
            }

            // MARK: Issues
            ForEach(issuesBySeverity, id: \.0) { severity, issues in
                Section {
                    ForEach(issues) { issue in
                        IssueRowView(issue: issue)
                    }
                } header: {
                    Label(
                        "\(severity.displayName) (\(issues.count))",
                        systemImage: severityIcon(for: severity)
                    )
                    .foregroundStyle(severityColor(for: severity))
                }
            }

            if report.issues.isEmpty {
                Section {
                    Label("No issues found — clean project!", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
            }
        }
        .navigationTitle(URL(fileURLWithPath: report.projectPath).lastPathComponent)
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Helpers

    private func severityIcon(for severity: IssueSeverity) -> String {
        switch severity {
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    private func severityColor(for severity: IssueSeverity) -> Color {
        switch severity {
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

// MARK: - Metric Row

private struct MetricRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}

// MARK: - Issue Row

private struct IssueRowView: View {
    let issue: CodeIssue

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(issue.message)
                .font(.subheadline)
            HStack(spacing: 8) {
                Text(URL(fileURLWithPath: issue.filePath).lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let line = issue.lineNumber {
                    Text("Line \(line)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !issue.ruleId.isEmpty {
                    Text(issue.ruleId)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        ReportDetailView(report: AnalysisReport(
            projectPath: "/Users/dev/MyProject",
            issues: [
                CodeIssue(severity: .error, message: "Undefined variable 'foo'", filePath: "/src/main.swift", lineNumber: 42, ruleId: "undefined-var"),
                CodeIssue(severity: .warning, message: "Unused import", filePath: "/src/utils.swift", lineNumber: 3, ruleId: "unused-import"),
                CodeIssue(severity: .info, message: "TODO: refactor this", filePath: "/src/main.swift", lineNumber: 10, ruleId: "todo-marker")
            ],
            metrics: CodeMetrics(totalFiles: 12, linesOfCode: 3400, complexity: 5.2, testCoverage: 0.72),
            summary: "Found 3 issues across 12 files."
        ))
    }
}
