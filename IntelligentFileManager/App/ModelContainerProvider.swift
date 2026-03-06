import Foundation
import SwiftData

enum ModelContainerProvider {
    static func shared() throws -> ModelContainer {
        let schema = Schema([
            ManagedFile.self,
            ConversationThread.self,
            ChatMessage.self,
            ActionStep.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [config])
    }

    static func preview() throws -> ModelContainer {
        let schema = Schema([
            ManagedFile.self,
            ConversationThread.self,
            ChatMessage.self,
            ActionStep.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])

        // Seed preview data
        let context = container.mainContext

        let file1 = ManagedFile(
            name: "ProjectPlan.pdf",
            path: "/Documents/ProjectPlan.pdf",
            fileExtension: "pdf",
            size: 512_000,
            classificationLabel: "Document",
            classificationConfidence: 0.95,
            tags: ["planning", "2024"]
        )
        let file2 = ManagedFile(
            name: "photo.jpg",
            path: "/Photos/photo.jpg",
            fileExtension: "jpg",
            size: 2_048_000,
            classificationLabel: "Image",
            classificationConfidence: 0.88
        )
        let file3 = ManagedFile(
            name: "backup.zip",
            path: "/Archives/backup.zip",
            fileExtension: "zip",
            size: 10_240_000,
            isDuplicate: false
        )
        context.insert(file1)
        context.insert(file2)
        context.insert(file3)

        let thread = ConversationThread(title: "File Analysis Session", isActive: true)
        let msg1 = ChatMessage(content: "Classify all PDFs in Documents", role: "user", thread: thread)
        let msg2 = ChatMessage(content: "Found 3 PDFs. Classified as Document with 94% confidence.", role: "assistant", thread: thread)
        thread.messages = [msg1, msg2]
        context.insert(thread)

        let step = ActionStep(
            operationType: "classification",
            status: "completed",
            completedAt: Date(),
            inputPath: file1.path,
            outputPath: "Document"
        )
        context.insert(step)

        try? context.save()
        return container
    }
}
