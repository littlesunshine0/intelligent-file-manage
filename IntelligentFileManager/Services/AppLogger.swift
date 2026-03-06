import Foundation
import os

enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}

final class AppLogger {
    private static let subsystem = "com.intelligentfilemanager"

    private static func logger(for category: String) -> Logger {
        Logger(subsystem: subsystem, category: category)
    }

    static func debug(
        _ message: String,
        category: String = "App",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        logger(for: category).debug("[\(fileName):\(line)] \(function) — \(message)")
    }

    static func info(
        _ message: String,
        category: String = "App",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        logger(for: category).info("[\(fileName):\(line)] \(function) — \(message)")
    }

    static func warning(
        _ message: String,
        category: String = "App",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        logger(for: category).warning("[\(fileName):\(line)] \(function) — \(message)")
    }

    static func error(
        _ message: String,
        category: String = "App",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        logger(for: category).error("[\(fileName):\(line)] \(function) — \(message)")
    }

    // MARK: - Instance methods

    private let category: String

    init(category: String = "App") {
        self.category = category
    }

    func log(_ level: LogLevel, _ message: String, category: String) {
        let osLogger = AppLogger.logger(for: category)
        switch level {
        case .debug:
            osLogger.debug("\(message)")
        case .info:
            osLogger.info("\(message)")
        case .warning:
            osLogger.warning("\(message)")
        case .error:
            osLogger.error("\(message)")
        }
    }
}
