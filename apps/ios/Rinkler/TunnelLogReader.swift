import Foundation

enum TunnelLogReader {
    static func readLog() -> String {
        #if !DEBUG
        return "Detailed tunnel logs are disabled in production builds."
        #else
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: RinklerConstants.appGroupID
        ) else {
            return "ERROR: Can't access app group container"
        }

        let fileURL = container.appendingPathComponent(RinklerConstants.logFileName)
        if let content = try? String(contentsOf: fileURL, encoding: .utf8), !content.isEmpty {
            return content
        }
        return "(no extension logs found at \(fileURL.path))"
        #endif
    }
}
