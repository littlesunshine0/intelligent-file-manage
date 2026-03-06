import Foundation
import SwiftData

@Model
final class ManagedFile {
    var id: UUID
    var name: String
    var path: String
    var fileExtension: String
    var size: Int64
    var createdAt: Date
    var modifiedAt: Date
    var isEncrypted: Bool
    var classificationLabel: String?
    var classificationConfidence: Double
    var isDuplicate: Bool
    var duplicateOfId: UUID?
    var tags: [String]
    var checksum: String?
    var isIndexed: Bool

    init(
        id: UUID = UUID(),
        name: String,
        path: String,
        fileExtension: String = "",
        size: Int64 = 0,
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        isEncrypted: Bool = false,
        classificationLabel: String? = nil,
        classificationConfidence: Double = 0.0,
        isDuplicate: Bool = false,
        duplicateOfId: UUID? = nil,
        tags: [String] = [],
        checksum: String? = nil,
        isIndexed: Bool = false
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.fileExtension = fileExtension
        self.size = size
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.isEncrypted = isEncrypted
        self.classificationLabel = classificationLabel
        self.classificationConfidence = classificationConfidence
        self.isDuplicate = isDuplicate
        self.duplicateOfId = duplicateOfId
        self.tags = tags
        self.checksum = checksum
        self.isIndexed = isIndexed
    }
}
