import SwiftUI

struct ManifestFeatureView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @StateObject private var viewModel: ManifestViewModel

    init(appEnvironment: AppEnvironment) {
        _viewModel = StateObject(wrappedValue: ManifestViewModel(
            databaseService: appEnvironment.databaseService,
            jsonPipelineService: appEnvironment.jsonPipelineService
        ))
    }

    var body: some View {
        List {
            if viewModel.isNormalizing {
                Section {
                    HStack {
                        ProgressView()
                        Text("Normalizing files…")
                            .foregroundStyle(.secondary)
                            .padding(.leading, 8)
                    }
                }
            }

            if !viewModel.normalizedFiles.isEmpty {
                Section("Normalized Files (\(viewModel.normalizedFiles.count))") {
                    ForEach(viewModel.normalizedFiles, id: \.id) { file in
                        HStack {
                            Image(systemName: "doc.badge.checkmark")
                                .foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(file.name).font(.body)
                                if let label = file.classificationLabel {
                                    Text(label)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            Section("Operation History (\(viewModel.manifests.count))") {
                if viewModel.manifests.isEmpty {
                    Text("No operations yet.")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(viewModel.manifests, id: \.id) { step in
                        ActionStepRow(step: step)
                    }
                }
            }
        }
        .navigationTitle("Manifest & Normalize")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await viewModel.normalizeFiles() }
                } label: {
                    Label("Normalize", systemImage: "wand.and.stars")
                }
                .disabled(viewModel.isNormalizing)
            }
        }
        .task { await viewModel.loadManifests() }
    }
}

// MARK: - Action Step Row

private struct ActionStepRow: View {
    let step: ActionStep

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(step.operationType.capitalized)
                    .font(.headline)
                Spacer()
                StatusBadge(status: step.status)
            }
            if let input = step.inputPath {
                Text(URL(fileURLWithPath: input).lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Text(step.startedAt, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}

private struct StatusBadge: View {
    let status: String

    var color: Color {
        switch status {
        case "completed": return .green
        case "failed": return .red
        case "running": return .blue
        default: return .gray
        }
    }

    var body: some View {
        Text(status.capitalized)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

#Preview {
    let env = AppEnvironment(modelContainer: try! ModelContainerProvider.preview())
    NavigationStack {
        ManifestFeatureView(appEnvironment: env)
            .environmentObject(env)
    }
}
