import Foundation
import SwiftData

@Model
final class ActionStep {
    var id: UUID
    var operationType: String
    var status: String
    var startedAt: Date
    var completedAt: Date?
    var inputPath: String?
    var outputPath: String?
    var errorMessage: String?
    var relatedFileId: UUID?
    var metadata: [String: String]

    init(
        id: UUID = UUID(),
        operationType: String,
        status: String = "pending",
        startedAt: Date = Date(),
        completedAt: Date? = nil,
        inputPath: String? = nil,
        outputPath: String? = nil,
        errorMessage: String? = nil,
        relatedFileId: UUID? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.operationType = operationType
        self.status = status
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.inputPath = inputPath
        self.outputPath = outputPath
        self.errorMessage = errorMessage
        self.relatedFileId = relatedFileId
        self.metadata = metadata
    }
}
