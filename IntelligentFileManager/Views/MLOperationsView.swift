import SwiftUI

struct MLOperationsView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @StateObject private var viewModel: MLOperationsViewModel

    init(appEnvironment: AppEnvironment) {
        _viewModel = StateObject(wrappedValue: MLOperationsViewModel(
            mlOperationService: appEnvironment.mlOperationService,
            databaseService: appEnvironment.databaseService
        ))
    }

    var body: some View {
        List {
            if viewModel.isProcessing {
                Section {
                    HStack {
                        ProgressView()
                        Text("Running classification…")
                            .foregroundStyle(.secondary)
                            .padding(.leading, 8)
                    }
                }
            }

            if !viewModel.classificationResults.isEmpty {
                Section("Classification Results (\(viewModel.classificationResults.count))") {
                    ForEach(viewModel.classificationResults) { result in
                        HStack {
                            Image(systemName: "tag")
                                .foregroundStyle(.purple)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.fileName)
                                    .font(.body)
                                    .lineLimit(1)
                                Text(result.label)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("Operations (\(viewModel.operations.count))") {
                if viewModel.operations.isEmpty {
                    Text("No operations recorded.")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(viewModel.operations, id: \.id) { step in
                        OperationRowView(step: step)
                    }
                }
            }
        }
        .navigationTitle("ML Operations")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    let files = appEnvironment.databaseService.fetchFiles()
                    Task { await viewModel.runClassification(on: files) }
                } label: {
                    Label("Classify All", systemImage: "sparkles")
                }
                .disabled(viewModel.isProcessing)

                Button {
                    viewModel.clearResults()
                } label: {
                    Label("Clear", systemImage: "trash")
                }
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
        .task { await viewModel.loadOperations() }
    }
}

// MARK: - Operation Row

private struct OperationRowView: View {
    let step: ActionStep

    var statusColor: Color {
        switch step.status {
        case "completed": return .green
        case "failed": return .red
        case "running": return .blue
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 3) {
                Text(step.operationType.capitalized)
                    .font(.subheadline)
                if let output = step.outputPath {
                    Text("→ \(output)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let err = step.errorMessage {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
            }
            Spacer()
            Text(step.startedAt, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    let env = AppEnvironment(modelContainer: try! ModelContainerProvider.preview())
    NavigationStack {
        MLOperationsView(appEnvironment: env)
            .environmentObject(env)
    }
}
