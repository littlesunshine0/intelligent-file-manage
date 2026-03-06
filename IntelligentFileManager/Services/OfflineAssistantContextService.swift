import Foundation

@MainActor
class OfflineAssistantContextService: ObservableObject {
    @Published var contextResults: [ConversationThread] = []

    var databaseService: DatabaseService

    /// In-memory cache of all conversations. `nil` means the cache is invalid and must be
    /// re-populated from the database. An empty array is a valid (and cached) empty result,
    /// so we never hit the DB again just because the history is empty.
    private var cachedConversations: [ConversationThread]?

    init(databaseService: DatabaseService) {
        self.databaseService = databaseService
    }

    // MARK: - Cache

    /// Clears the in-memory cache so the next search re-fetches from the database.
    /// Call this after conversations are added or removed.
    func invalidateCache() {
        cachedConversations = nil
    }

    // MARK: - Search

    func search(query: String) async -> [ConversationThread] {
        // Populate cache on first call (or after invalidation).
        if cachedConversations == nil {
            cachedConversations = databaseService.fetchConversations()
        }
        let all = cachedConversations ?? []

        guard !query.isEmpty else {
            contextResults = all
            return all
        }

        let lowercased = query.lowercased()
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
