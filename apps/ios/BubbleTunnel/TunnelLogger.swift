import Foundation
import os

/// Writes log lines to both:
/// 1. Apple's unified logging system (streamable via `log stream` over USB)
/// 2. A shared file in the app group container (viewable in-app)
final class TunnelLogger {

    static let shared = TunnelLogger()

    private let fileURL: URL?
    private let lock = NSLock()

    // os.Logger for real-time streaming to Mac via USB
    private static let osLog = Logger(
        subsystem: BubbleConstants.logSubsystem,
        category: "tunnel"
    )

    // Separate logger for per-connection data (filterable)
    static let connectionLog = Logger(
        subsystem: BubbleConstants.logSubsystem,
        category: "connection"
    )

    private static let dateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        return f
    }()

    private init() {
        if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: BubbleConstants.appGroupID) {
            self.fileURL = container.appendingPathComponent(BubbleConstants.logFileName)
        } else {
            self.fileURL = nil
        }
    }

    func log(_ message: String, function: String = #function) {
        let timestamp = Self.dateFormatter.string(from: Date())
        let line = "[\(timestamp)] [\(function)] \(message)\n"

        // Stream to Mac via USB (Console.app / `log stream`)
        Self.osLog.log("[\(function, privacy: .public)] \(message, privacy: .public)")

        guard let fileURL = fileURL else { return }

        lock.lock()
        defer { lock.unlock() }

        // Log rotation: if file exceeds max size, trim to last half
        if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
           let size = attrs[.size] as? Int,
           size > BubbleConstants.maxLogSizeBytes {
            rotateLog(at: fileURL)
        }

        if let handle = try? FileHandle(forWritingTo: fileURL) {
            handle.seekToEndOfFile()
            if let data = line.data(using: .utf8) {
                handle.write(data)
            }
            handle.closeFile()
        } else {
            try? line.data(using: .utf8)?.write(to: fileURL, options: .atomic)
        }
    }

    /// Log connection-level data to the "connection" category for filtering
    func logConnection(_ message: String) {
        Self.connectionLog.log("\(message, privacy: .public)")
        // Also write to file for in-app viewing
        log(message)
    }

    func clear() {
        guard let fileURL = fileURL else { return }
        lock.lock()
        defer { lock.unlock() }
        try? "".data(using: .utf8)?.write(to: fileURL, options: .atomic)
    }

    static func readLog() -> String {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: BubbleConstants.appGroupID) else {
            return "(no app group container)"
        }
        let fileURL = container.appendingPathComponent(BubbleConstants.logFileName)
        return (try? String(contentsOf: fileURL, encoding: .utf8)) ?? "(no logs yet)"
    }

    // MARK: - Private

    private func rotateLog(at fileURL: URL) {
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { return }
        let lines = content.components(separatedBy: "\n")
        let keepFrom = lines.count / 2
        let trimmed = lines[keepFrom...].joined(separator: "\n")
        try? trimmed.data(using: .utf8)?.write(to: fileURL, options: .atomic)
    }
}
