import Foundation

@MainActor
class SettingsService: ObservableObject {
    private enum Keys {
        static let encryptionEnabled = "encryptionEnabled"
        static let defaultDirectoryBookmark = "defaultDirectoryBookmark"
        static let autoClassifyEnabled = "autoClassifyEnabled"
        static let mlModelPath = "mlModelPath"
        static let maxFileSizeMB = "maxFileSizeMB"
    }

    @Published var encryptionEnabled: Bool {
        didSet { UserDefaults.standard.set(encryptionEnabled, forKey: Keys.encryptionEnabled) }
    }

    @Published var defaultDirectory: URL {
        didSet {
            if let bookmark = try? defaultDirectory.bookmarkData() {
                UserDefaults.standard.set(bookmark, forKey: Keys.defaultDirectoryBookmark)
            }
        }
    }

    @Published var autoClassifyEnabled: Bool {
        didSet { UserDefaults.standard.set(autoClassifyEnabled, forKey: Keys.autoClassifyEnabled) }
    }

    @Published var mlModelPath: String {
        didSet { UserDefaults.standard.set(mlModelPath, forKey: Keys.mlModelPath) }
    }

    @Published var maxFileSizeMB: Int {
        didSet { UserDefaults.standard.set(maxFileSizeMB, forKey: Keys.maxFileSizeMB) }
    }

    init() {
        let defaults = UserDefaults.standard

        self.encryptionEnabled = defaults.bool(forKey: Keys.encryptionEnabled)
        self.autoClassifyEnabled = defaults.bool(forKey: Keys.autoClassifyEnabled)
        self.mlModelPath = defaults.string(forKey: Keys.mlModelPath) ?? ""
        self.maxFileSizeMB = defaults.integer(forKey: Keys.maxFileSizeMB) == 0
            ? 500
            : defaults.integer(forKey: Keys.maxFileSizeMB)

        if let bookmarkData = defaults.data(forKey: Keys.defaultDirectoryBookmark),
           let resolved = try? URL(
               resolvingBookmarkData: bookmarkData,
               options: .withoutUI,
               relativeTo: nil,
               bookmarkDataIsStale: nil
           ) {
            self.defaultDirectory = resolved
        } else {
            self.defaultDirectory = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first ?? URL(fileURLWithPath: NSHomeDirectory())
        }
    }

    func resetToDefaults() {
        encryptionEnabled = false
        autoClassifyEnabled = false
        mlModelPath = ""
        maxFileSizeMB = 500
        defaultDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first ?? URL(fileURLWithPath: NSHomeDirectory())
    }
}
