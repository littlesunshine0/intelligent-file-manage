import SwiftUI

struct IngestionView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @StateObject private var viewModel: IngestionViewModel
    @State private var isDirPickerPresented = false
    @State private var isJSONPickerPresented = false

    init(appEnvironment: AppEnvironment) {
        _viewModel = StateObject(wrappedValue: IngestionViewModel(
            fileRepository: appEnvironment.fileRepository,
            jsonPipelineService: appEnvironment.jsonPipelineService,
            databaseService: appEnvironment.databaseService,
            settingsService: appEnvironment.settingsService,
            mlOperationService: appEnvironment.mlOperationService
        ))
    }

    var body: some View {
        List {
            Section("Source") {
                Button {
                    isDirPickerPresented = true
                } label: {
                    Label(
                        viewModel.selectedDirectory?.lastPathComponent ?? "Choose Directory",
                        systemImage: "folder"
                    )
                }

                Button {
                    isJSONPickerPresented = true
                } label: {
                    Label("Import JSON Manifest", systemImage: "doc.badge.plus")
                }
            }

            if viewModel.isIngesting {
                Section("Progress") {
                    VStack(alignment: .leading, spacing: 6) {
                        ProgressView(value: viewModel.progress)
                        Text("\(Int(viewModel.progress * 100))% complete")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            if !viewModel.ingestedFiles.isEmpty {
                Section("Ingested Files (\(viewModel.ingestedFiles.count))") {
                    ForEach(viewModel.ingestedFiles, id: \.id) { file in
                        HStack {
                            Image(systemName: "doc")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(file.name).font(.body)
                                Text(ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Ingestion")
        .fileImporter(
            isPresented: $isDirPickerPresented,
            allowedContentTypes: [.folder]
        ) { result in
            if case .success(let url) = result {
                Task { await viewModel.ingestDirectory(url) }
            }
        }
        .fileImporter(
            isPresented: $isJSONPickerPresented,
            allowedContentTypes: [.json]
        ) { result in
            if case .success(let url) = result {
                Task { await viewModel.ingestJSONFile(url) }
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

#Preview {
    let env = AppEnvironment(modelContainer: try! ModelContainerProvider.preview())
    NavigationStack {
        IngestionView(appEnvironment: env)
            .environmentObject(env)
    }
}
