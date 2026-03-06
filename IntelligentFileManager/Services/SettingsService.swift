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
        didSet {
            UserDefaults.standard.set(encryptionEnabled, forKey: Keys.encryptionEnabled)
        }
    }

    @Published var defaultDirectory: URL {
        didSet {
            do {
                let bookmark = try defaultDirectory.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                UserDefaults.standard.set(bookmark, forKey: Keys.defaultDirectoryBookmark)
            } catch {
                AppLogger.warning(
                    "Failed to persist default directory bookmark: \(error.localizedDescription)",
                    category: "Settings"
                )
            }
        }
    }

    @Published var autoClassifyEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoClassifyEnabled, forKey: Keys.autoClassifyEnabled)
        }
    }

    @Published var mlModelPath: String {
        didSet {
            UserDefaults.standard.set(mlModelPath, forKey: Keys.mlModelPath)
        }
    }

    @Published var maxFileSizeMB: Int {
        didSet {
            UserDefaults.standard.set(maxFileSizeMB, forKey: Keys.maxFileSizeMB)
        }
    }

    init() {
        let defaults = UserDefaults.standard

        self.encryptionEnabled = defaults.bool(forKey: Keys.encryptionEnabled)
        self.autoClassifyEnabled = defaults.bool(forKey: Keys.autoClassifyEnabled)
        self.mlModelPath = defaults.string(forKey: Keys.mlModelPath) ?? ""
        self.maxFileSizeMB = defaults.integer(forKey: Keys.maxFileSizeMB) == 0
            ? 500
            : defaults.integer(forKey: Keys.maxFileSizeMB)

        let fallbackDirectory =
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory())

        if let bookmarkData = defaults.data(forKey: Keys.defaultDirectoryBookmark) {
            var isStale = false

            do {
                let resolved = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )

                self.defaultDirectory = resolved

                if isStale {
                    if let refreshed = try? resolved.bookmarkData(
                        options: .withSecurityScope,
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    ) {
                        defaults.set(refreshed, forKey: Keys.defaultDirectoryBookmark)
                    }
                    AppLogger.warning(
                        "Default directory bookmark was stale; refreshed.",
                        category: "Settings"
                    )
                }
            } catch {
                self.defaultDirectory = fallbackDirectory
                AppLogger.warning(
                    "Failed to resolve default directory bookmark: \(error.localizedDescription). Falling back to Documents.",
                    category: "Settings"
                )
            }
        } else {
            self.defaultDirectory = fallbackDirectory
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