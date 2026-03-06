import Foundation
import SwiftUI

// MARK: - Protocol

protocol FileRepository {
    func scanDirectory(_ url: URL) async throws -> [ManagedFile]
    func moveFile(_ file: ManagedFile, to url: URL) async throws
    func deleteFile(_ file: ManagedFile) async throws
    func duplicateDetection(files: [ManagedFile]) async -> [UUID: [ManagedFile]]
}

// MARK: - Default Implementation

class DefaultFileRepository: FileRepository, ObservableObject {
    @Published var files: [ManagedFile] = []

    private let databaseService: DatabaseService
    private let settingsService: SettingsService
    private let fileManager = FileManager.default

    init(databaseService: DatabaseService, settingsService: SettingsService) {
        self.databaseService = databaseService
        self.settingsService = settingsService
    }

    // MARK: - Protocol Methods

    func scanDirectory(_ url: URL) async throws -> [ManagedFile] {
        guard url.startAccessingSecurityScopedResource() else {
            throw FileRepositoryError.accessDenied(url)
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let resourceKeys: [URLResourceKey] = [
            .nameKey, .fileSizeKey, .creationDateKey,
            .contentModificationDateKey, .isRegularFileKey
        ]
        let contents = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles]
        )

        var scanned: [ManagedFile] = []
        let maxBytes = Int64(settingsService.maxFileSizeMB) * 1024 * 1024
        for fileURL in contents {
            let resources = try fileURL.resourceValues(forKeys: Set(resourceKeys))
            guard resources.isRegularFile == true else { continue }

            let fileSize = Int64(resources.fileSize ?? 0)
            guard fileSize <= maxBytes else { continue }

            let ext = fileURL.pathExtension.lowercased()
            let managed = ManagedFile(
                name: resources.name ?? fileURL.lastPathComponent,
                path: fileURL.path,
                fileExtension: ext,
                size: fileSize,
                createdAt: resources.creationDate ?? Date(),
                modifiedAt: resources.contentModificationDate ?? Date()
            )
            scanned.append(managed)
        }
        return scanned
    }

    func moveFile(_ file: ManagedFile, to url: URL) async throws {
        let source = URL(fileURLWithPath: file.path)
        let destination = url.appendingPathComponent(file.name)
        try fileManager.moveItem(at: source, to: destination)
        file.path = destination.path
        await MainActor.run { databaseService.save() }
    }

    func deleteFile(_ file: ManagedFile) async throws {
        let fileURL = URL(fileURLWithPath: file.path)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
        await MainActor.run { databaseService.delete(file) }
    }

    func duplicateDetection(files: [ManagedFile]) async -> [UUID: [ManagedFile]] {
        var checksumGroups: [String: [ManagedFile]] = [:]
        for file in files {
            let key = file.checksum ?? "\(file.name)-\(file.size)"
            checksumGroups[key, default: []].append(file)
        }
        var duplicates: [UUID: [ManagedFile]] = [:]
        for group in checksumGroups.values where group.count > 1 {
            let primary = group[0]
            duplicates[primary.id] = group
        }
        return duplicates
    }

    // MARK: - Helpers

    func refreshFiles(from directory: URL) async {
        do {
            let scanned = try await scanDirectory(directory)
            for file in scanned {
                await MainActor.run { databaseService.insert(file) }
            }
            await MainActor.run {
                self.files = databaseService.fetchFiles()
            }
        } catch {
            AppLogger.error("refreshFiles failed: \(error.localizedDescription)", category: "FileRepository")
        }
    }
}

// MARK: - Errors

enum FileRepositoryError: LocalizedError {
    case accessDenied(URL)
    case fileNotFound(String)

    var errorDescription: String? {
        switch self {
        case .accessDenied(let url):
            return "Access denied to \(url.lastPathComponent)"
        case .fileNotFound(let path):
            return "File not found at \(path)"
        }
    }
}
