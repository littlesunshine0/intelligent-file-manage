import Foundation

@MainActor
class JSONResourcePipelineService: ObservableObject {
    @Published var extractedConversations: [ConversationThread] = []

    // MARK: - Resource Extraction

    func extractResources(from url: URL) async throws -> [String: Any] {
        // Perform blocking file I/O on a background thread to avoid blocking the main actor.
        let data = try await Task.detached(priority: .userInitiated) {
            try Data(contentsOf: url)
        }.value
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PipelineError.invalidFormat
        }
        return json
    }

    // MARK: - Conversation Parsing

    func parseConversationData(from json: [String: Any]) -> [ConversationThread] {
        guard let threads = json["conversations"] as? [[String: Any]] else {
            extractedConversations = []
            return []
        }
        let parsed = threads.compactMap { dict -> ConversationThread? in
            guard let title = dict["title"] as? String else { return nil }
            let thread = ConversationThread(title: title)
            if let sourceFile = dict["sourceFile"] as? String {
                thread.sourceFile = sourceFile
            }
            if let rawMessages = dict["messages"] as? [[String: Any]] {
                thread.messages = rawMessages.compactMap { msg -> ChatMessage? in
                    guard
                        let content = msg["content"] as? String,
                        let role = msg["role"] as? String
                    else { return nil }
                    let message = ChatMessage(content: content, role: role, thread: thread)
                    return message
                }
            }
            return thread
        }
        // Replace (don't accumulate) so repeated calls don't duplicate state.
        extractedConversations = parsed
        return parsed
    }

    // MARK: - Ingestion Manifest

    func processIngestionManifest(_ manifest: [String: Any]) async throws -> [ManagedFile] {
        guard let files = manifest["files"] as? [[String: Any]] else {
            return []
        }
        return files.compactMap { dict -> ManagedFile? in
            guard
                let name = dict["name"] as? String,
                let path = dict["path"] as? String
            else { return nil }

            let ext = (dict["extension"] as? String) ?? URL(fileURLWithPath: path).pathExtension
            let size = (dict["size"] as? Int).map { Int64($0) } ?? 0
            let tags = (dict["tags"] as? [String]) ?? []
            let label = dict["classificationLabel"] as? String

            return ManagedFile(
                name: name,
                path: path,
                fileExtension: ext,
                size: size,
                tags: tags,
                classificationLabel: label
            )
        }
    }
}

// MARK: - Errors

enum PipelineError: LocalizedError {
    case invalidFormat
    case missingField(String)

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "The JSON file has an invalid format."
        case .missingField(let field):
            return "Missing required field: \(field)"
        }
    }
}
