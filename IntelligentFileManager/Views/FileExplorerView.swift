import SwiftUI

struct FileExplorerView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @StateObject private var viewModel: FileExplorerViewModel
    @State private var isFileImporterPresented = false
    @State private var showDocumentViewer = false

    init(appEnvironment: AppEnvironment) {
        _viewModel = StateObject(wrappedValue: FileExplorerViewModel(
            fileRepository: appEnvironment.fileRepository,
            mlOperationService: appEnvironment.mlOperationService,
            databaseService: appEnvironment.databaseService
        ))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading files…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredFiles.isEmpty {
                ContentUnavailableView(
                    "No Files",
                    systemImage: "folder.badge.questionmark",
                    description: Text("Scan a directory to get started.")
                )
            } else {
                List(viewModel.filteredFiles, id: \.id, selection: $viewModel.selectedFile) { file in
                    FileRowView(file: file, duplicates: viewModel.duplicates)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Files")
        .searchable(text: $viewModel.searchQuery, prompt: "Search files")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    isFileImporterPresented = true
                } label: {
                    Label("Scan Directory", systemImage: "folder.badge.plus")
                }

                Button {
                    Task { await viewModel.classifyFiles() }
                } label: {
                    Label("Classify", systemImage: "sparkles")
                }

                Button {
                    Task { await viewModel.detectDuplicates() }
                } label: {
                    Label("Find Duplicates", systemImage: "doc.on.doc")
                }
            }
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.folder]
        ) { result in
            if case .success(let url) = result {
                Task { await viewModel.loadFiles(from: url) }
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
        .sheet(item: $viewModel.selectedFile) { file in
            NavigationStack {
                DocumentViewer(file: .constant(file))
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { viewModel.selectedFile = nil }
                        }
                    }
            }
        }
    }
}

// MARK: - File Row

private struct FileRowView: View {
    let file: ManagedFile
    let duplicates: [UUID: [ManagedFile]]

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName(for: file.fileExtension))
                .foregroundStyle(.blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(file.name)
                        .font(.body)
                        .lineLimit(1)
                    if file.isDuplicate {
                        Image(systemName: "doc.on.doc.fill")
                            .foregroundStyle(.orange)
                            .imageScale(.small)
                    }
                }
                HStack(spacing: 8) {
                    Text(ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let label = file.classificationLabel {
                        Text(label)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }

    private func iconName(for ext: String) -> String {
        switch ext.lowercased() {
        case "jpg", "jpeg", "png", "gif", "heic", "webp": return "photo"
        case "mp3", "m4a", "wav", "aiff": return "music.note"
        case "mp4", "mov", "avi", "mkv": return "film"
        case "pdf": return "doc.richtext"
        case "zip", "tar", "gz": return "archivebox"
        case "swift", "py", "js", "ts": return "chevron.left.forwardslash.chevron.right"
        default: return "doc"
        }
    }
}

#Preview {
    let env = AppEnvironment(modelContainer: try! ModelContainerProvider.preview())
    NavigationStack {
        FileExplorerView(appEnvironment: env)
            .environmentObject(env)
    }
}
