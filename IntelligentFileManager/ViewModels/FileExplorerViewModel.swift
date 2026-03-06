import Foundation
import SwiftUI

@MainActor
class FileExplorerViewModel: ObservableObject {
    @Published var files: [ManagedFile] = []
    @Published var selectedFile: ManagedFile? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var searchQuery: String = ""
    @Published var duplicates: [UUID: [ManagedFile]] = [:]

    var fileRepository: DefaultFileRepository
    var mlOperationService: MLOperationService
    var databaseService: DatabaseService

    init(
        fileRepository: DefaultFileRepository,
        mlOperationService: MLOperationService,
        databaseService: DatabaseService
    ) {
        self.fileRepository = fileRepository
        self.mlOperationService = mlOperationService
        self.databaseService = databaseService
    }

    // MARK: - Computed

    var filteredFiles: [ManagedFile] {
        guard !searchQuery.isEmpty else { return files }
        let q = searchQuery.lowercased()
        return files.filter {
            $0.name.lowercased().contains(q) ||
            $0.fileExtension.lowercased().contains(q) ||
            ($0.classificationLabel?.lowercased().contains(q) ?? false)
        }
    }

    // MARK: - Actions

    func loadFromDatabase() {
        files = databaseService.fetchFiles()
    }

    func loadFiles(from directory: URL) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let scanned = try await fileRepository.scanDirectory(directory)
            databaseService.insertMany(scanned)
            files = databaseService.fetchFiles()
            AppLogger.info(
                "Loaded \(files.count) files from \(directory.lastPathComponent)",
                category: "FileExplorer"
            )
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error("loadFiles failed: \(error.localizedDescription)", category: "FileExplorer")
        }
    }

    func deleteFile(_ file: ManagedFile) async {
        do {
            try await fileRepository.deleteFile(file)
            files = databaseService.fetchFiles()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func classifyFiles() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await mlOperationService.processFiles(files)
            files = databaseService.fetchFiles()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func detectDuplicates() async {
        duplicates = await mlOperationService.runDuplicateDetection(files: files)
        files = databaseService.fetchFiles()
    }
}