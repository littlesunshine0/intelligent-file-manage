import Foundation
import SwiftData

@MainActor
class DatabaseService: ObservableObject {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = modelContainer.mainContext
    }

    // MARK: - Persistence

    func save() {
        do {
            try modelContext.save()
        } catch {
            AppLogger.error("Failed to save context: \(error.localizedDescription)", category: "Database")
        }
    }

    func insert<T: PersistentModel>(_ model: T, saveImmediately: Bool = true) {
        modelContext.insert(model)
        if saveImmediately {
            save()
        }
    }

    func insertMany<T: PersistentModel>(_ models: [T], saveImmediately: Bool = true) {
        for model in models {
            modelContext.insert(model)
        }
        if saveImmediately {
            save()
        }
    }

    func delete<T: PersistentModel>(_ model: T) {
        modelContext.delete(model)
        save()
    }

    // MARK: - Fetch

    func fetchFiles() -> [ManagedFile] {
        let descriptor = FetchDescriptor<ManagedFile>(
            sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            AppLogger.error("Failed to fetch files: \(error.localizedDescription)", category: "Database")
            return []
        }
    }

    func fetchFiles(matching query: String) -> [ManagedFile] {
        let lowercased = query.lowercased()
        let descriptor = FetchDescriptor<ManagedFile>(
            predicate: #Predicate<ManagedFile> { file in
                file.name.localizedStandardContains(lowercased) ||
                file.path.localizedStandardContains(lowercased)
            },
            sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            AppLogger.error("Failed to fetch files matching '\(query)': \(error.localizedDescription)", category: "Database")
            return []
        }
    }

    func fetchConversations() -> [ConversationThread] {
        let descriptor = FetchDescriptor<ConversationThread>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            AppLogger.error("Failed to fetch conversations: \(error.localizedDescription)", category: "Database")
            return []
        }
    }

    func fetchActionSteps() -> [ActionStep] {
        let descriptor = FetchDescriptor<ActionStep>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            AppLogger.error("Failed to fetch action steps: \(error.localizedDescription)", category: "Database")
            return []
        }
    }
}