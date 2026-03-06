import Foundation
import SwiftData

@Model
final class ConversationThread {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.thread)
    var messages: [ChatMessage]
    var sourceFile: String?
    var isActive: Bool

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        messages: [ChatMessage] = [],
        sourceFile: String? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = messages
        self.sourceFile = sourceFile
        self.isActive = isActive
    }
}
