import Foundation
import SwiftData

@Model
final class ChatMessage {
    var id: UUID
    var content: String
    var role: String
    var timestamp: Date
    var thread: ConversationThread?

    init(
        id: UUID = UUID(),
        content: String,
        role: String,
        timestamp: Date = Date(),
        thread: ConversationThread? = nil
    ) {
        self.id = id
        self.content = content
        self.role = role
        self.timestamp = timestamp
        self.thread = thread
    }
}
