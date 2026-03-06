import Foundation
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var encryptionEnabled: Bool
    @Published var defaultDirectoryPath: String
    @Published var autoClassifyEnabled: Bool
    @Published var maxFileSizeMB: Int

    var settingsService: SettingsService

    private var cancellables = Set<AnyCancellable>()

    init(settingsService: SettingsService) {
        self.settingsService = settingsService

        self.encryptionEnabled = settingsService.encryptionEnabled
        self.defaultDirectoryPath = settingsService.defaultDirectory.path
        self.autoClassifyEnabled = settingsService.autoClassifyEnabled
        self.maxFileSizeMB = settingsService.maxFileSizeMB

        // Observe settingsService changes and sync to local published properties
        settingsService.$encryptionEnabled
            .sink { [weak self] value in self?.encryptionEnabled = value }
            .store(in: &cancellables)

        settingsService.$defaultDirectory
            .sink { [weak self] url in self?.defaultDirectoryPath = url.path }
            .store(in: &cancellables)

        settingsService.$autoClassifyEnabled
            .sink { [weak self] value in self?.autoClassifyEnabled = value }
            .store(in: &cancellables)

        settingsService.$maxFileSizeMB
            .sink { [weak self] value in self?.maxFileSizeMB = value }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func applyEncryptionSettings() {
        settingsService.encryptionEnabled = encryptionEnabled
        AppLogger.info("Encryption \(encryptionEnabled ? "enabled" : "disabled")", category: "Settings")
    }

    func resetToDefaults() {
        settingsService.resetToDefaults()
        AppLogger.info("Settings reset to defaults", category: "Settings")
    }

    func applyChanges() {
        settingsService.encryptionEnabled = encryptionEnabled
        settingsService.autoClassifyEnabled = autoClassifyEnabled
        settingsService.maxFileSizeMB = maxFileSizeMB
        let url = URL(fileURLWithPath: defaultDirectoryPath)
        settingsService.defaultDirectory = url
    }
}
