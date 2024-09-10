import Foundation

struct Logger {
    static func log(_ message: String) {
        let logMessage = "[\(Date())] \(message)"
        print(logMessage)
    }
}
