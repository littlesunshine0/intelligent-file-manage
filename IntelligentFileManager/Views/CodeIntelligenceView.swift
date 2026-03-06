import SwiftUI

struct CodeIntelligenceView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @StateObject private var viewModel: CodeIntelligenceViewModel
    @State private var isProjectPickerPresented = false

    init(appEnvironment: AppEnvironment) {
        let orchestrator = appEnvironment.codeIntelligenceOrchestrator
        _viewModel = StateObject(wrappedValue: CodeIntelligenceViewModel(orchestrator: orchestrator))
    }

    var body: some View {
        List {
            Section("Project") {
                HStack {
                    Label(
                        viewModel.selectedProjectPath?.lastPathComponent ?? "No project selected",
                        systemImage: "folder"
                    )
                    .foregroundStyle(viewModel.selectedProjectPath == nil ? .secondary : .primary)
                    Spacer()
                    Button("Select") {
                        isProjectPickerPresented = true
                    }
                    .buttonStyle(.bordered)
                }

                if let path = viewModel.selectedProjectPath {
                    Button {
                        Task { await viewModel.analyzeProject(at: path) }
                    } label: {
                        if viewModel.isAnalyzing {
                            HStack {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Analyzing…")
                            }
                        } else {
                            Label("Analyze Project", systemImage: "magnifyingglass.circle.fill")
                        }
                    }
                    .disabled(viewModel.isAnalyzing)
                }
            }

            if !viewModel.analysisResults.isEmpty {
                Section("Reports (\(viewModel.analysisResults.count))") {
                    ForEach(viewModel.analysisResults) { report in
                        NavigationLink(destination: ReportDetailView(report: report)) {
                            ReportSummaryRow(report: report)
                        }
                    }
                }
            } else if !viewModel.isAnalyzing {
                ContentUnavailableView(
                    "No Reports",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Select a project and run analysis.")
                )
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Code Analysis")
        .fileImporter(
            isPresented: $isProjectPickerPresented,
            allowedContentTypes: [.folder]
        ) { result in
            if case .success(let url) = result {
                viewModel.selectedProjectPath = url
            }
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

// MARK: - Report Summary Row

private struct ReportSummaryRow: View {
    let report: AnalysisReport

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(URL(fileURLWithPath: report.projectPath).lastPathComponent)
                .font(.headline)
                .lineLimit(1)
            HStack(spacing: 12) {
                Label("\(report.metrics.totalFiles) files", systemImage: "doc.on.doc")
                Label("\(report.issues.filter { $0.severity == .error }.count) errors", systemImage: "xmark.circle")
                    .foregroundStyle(.red)
                Label("\(report.issues.filter { $0.severity == .warning }.count) warnings", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            Text(report.timestamp, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let env = AppEnvironment(modelContainer: try! ModelContainerProvider.preview())
    NavigationStack {
        CodeIntelligenceView(appEnvironment: env)
            .environmentObject(env)
    }
}
