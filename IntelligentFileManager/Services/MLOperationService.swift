import Foundation

@MainActor
class MLOperationService: ObservableObject {
    @Published var operations: [ActionStep] = []
    @Published var isProcessing: Bool = false

    let databaseService: DatabaseService
    let jsonPipelineService: JSONResourcePipelineService

    private let classificationLabels = [
        "Document", "Image", "Audio", "Video",
        "Archive", "Source Code", "Spreadsheet", "Presentation", "Other"
    ]

    init(databaseService: DatabaseService, jsonPipelineService: JSONResourcePipelineService) {
        self.databaseService = databaseService
        self.jsonPipelineService = jsonPipelineService
    }

    // MARK: - Classification

    func classifyFile(_ file: ManagedFile) async throws -> String {
        let step = ActionStep(
            operationType: "classification",
            status: "running",
            inputPath: file.path,
            relatedFileId: file.id
        )
        databaseService.insert(step)

        do {
            // Heuristic classification based on file extension.
            // Confidence reflects whether the extension has a known explicit mapping (0.92)
            // or falls back to "Other" (0.60).
            let label = inferLabel(for: file.fileExtension)
            let confidence = label == "Other" ? 0.60 : 0.92

            file.classificationLabel = label
            file.classificationConfidence = confidence
            databaseService.save()

            step.status = "completed"
            step.completedAt = Date()
            step.outputPath = label
            databaseService.save()

            AppLogger.info("Classified \(file.name) as \(label)", category: "MLOperation")
            return label
        } catch {
            step.status = "failed"
            step.errorMessage = error.localizedDescription
            step.completedAt = Date()
            databaseService.save()
            throw error
        }
    }

    func processFiles(_ files: [ManagedFile]) async throws {
        isProcessing = true
        defer { isProcessing = false }

        for file in files {
            _ = try await classifyFile(file)
        }
        operations = databaseService.fetchActionSteps()
    }

    func runDuplicateDetection(files: [ManagedFile]) async -> [UUID: [ManagedFile]] {
        let step = ActionStep(operationType: "duplicateDetection", status: "running")
        databaseService.insert(step)

        var checksumGroups: [String: [ManagedFile]] = [:]
        for file in files {
            let key = file.checksum ?? "\(file.name)-\(file.size)"
            checksumGroups[key, default: []].append(file)
        }

        var duplicates: [UUID: [ManagedFile]] = [:]
        for group in checksumGroups.values where group.count > 1 {
            let primary = group[0]
            duplicates[primary.id] = group
            for dup in group.dropFirst() {
                dup.isDuplicate = true
                dup.duplicateOfId = primary.id
            }
        }
        databaseService.save()

        step.status = "completed"
        step.completedAt = Date()
        databaseService.save()
        operations = databaseService.fetchActionSteps()
        return duplicates
    }

    // MARK: - Private Helpers

    private func inferLabel(for ext: String) -> String {
        switch ext.lowercased() {
        case "jpg", "jpeg", "png", "gif", "bmp", "heic", "webp":
            return "Image"
        case "mp3", "m4a", "wav", "aiff", "flac":
            return "Audio"
        case "mp4", "mov", "avi", "mkv", "m4v":
            return "Video"
        case "pdf", "doc", "docx", "txt", "rtf", "md":
            return "Document"
        case "xls", "xlsx", "csv":
            return "Spreadsheet"
        case "ppt", "pptx", "key":
            return "Presentation"
        case "zip", "tar", "gz", "7z", "rar":
            return "Archive"
        case "swift", "py", "js", "ts", "java", "kt", "cpp", "c", "h", "rb", "go", "rs":
            return "Source Code"
        default:
            return "Other"
        }
    }
}
