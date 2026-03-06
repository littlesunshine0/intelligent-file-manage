import Foundation

@MainActor
class OfflineAssistantContextService: ObservableObject {
    @Published var contextResults: [ConversationThread] = []

    var databaseService: DatabaseService

    init(databaseService: DatabaseService) {
        self.databaseService = databaseService
    }

    // MARK: - Search

    func search(query: String) async -> [ConversationThread] {
        guard !query.isEmpty else {
            let all = databaseService.fetchConversations()
            contextResults = all
            return all
        }
        let lowercased = query.lowercased()
        let all = databaseService.fetchConversations()
        let filtered = all.filter { thread in
            thread.title.lowercased().contains(lowercased) ||
            thread.messages.contains { $0.content.lowercased().contains(lowercased) }
        }
        contextResults = filtered
        return filtered
    }

    // MARK: - Context Building

    func getRelevantContext(for query: String) async -> String {
        let threads = await search(query: query)
        guard !threads.isEmpty else {
            return "No relevant conversation history found for: \(query)"
        }
        var contextParts: [String] = ["Relevant conversation history:"]
        for thread in threads.prefix(3) {
            contextParts.append("Thread: \(thread.title)")
            for message in thread.messages.prefix(5) {
                let roleLabel = message.role == "user" ? "User" : "Assistant"
                contextParts.append("  \(roleLabel): \(message.content)")
            }
        }
        return contextParts.joined(separator: "\n")
    }
}
