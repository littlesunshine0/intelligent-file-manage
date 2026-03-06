import Foundation
import SwiftData

@MainActor
class AppEnvironment: ObservableObject {
    let databaseService: DatabaseService
    let fileRepository: DefaultFileRepository
    let settingsService: SettingsService
    let mlOperationService: MLOperationService
    let jsonPipelineService: JSONResourcePipelineService
    let offlineAssistantService: OfflineAssistantContextService

    init(modelContainer: ModelContainer) {
        let settings = SettingsService()
        let db = DatabaseService(modelContainer: modelContainer)
        let jsonPipeline = JSONResourcePipelineService()
        let repo = DefaultFileRepository(databaseService: db, settingsService: settings)
        let ml = MLOperationService(databaseService: db, jsonPipelineService: jsonPipeline)
        let offline = OfflineAssistantContextService(databaseService: db)

        self.settingsService = settings
        self.databaseService = db
        self.jsonPipelineService = jsonPipeline
        self.fileRepository = repo
        self.mlOperationService = ml
        self.offlineAssistantService = offline
    }
}
