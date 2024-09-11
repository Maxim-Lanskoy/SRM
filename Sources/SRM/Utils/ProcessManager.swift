import Foundation

struct ProcessManager {
    static let logsDirectory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".srm/logs")

    static func saveProcessInfo(_ process: ProcessInfo) throws {
        guard let data = process.encodeToJSON() else {
            throw RuntimeError("Failed to encode process info.")
        }
        let filePath = logsDirectory.appendingPathComponent("\(process.processName).json")
        try data.write(to: filePath)
    }

    static func fetchProcessInfo(for name: String) throws -> ProcessInfo.CodableProcessInfo? {
        let filePath = logsDirectory.appendingPathComponent("\(name).json")
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            return nil
        }
        let data = try Data(contentsOf: filePath)
        return ProcessInfo.decodeFromJSON(data)
    }

    static func log(for process: ProcessInfo) throws -> String {
        let logFile = logsDirectory.appendingPathComponent("\(process.processName).log")
        let logData = try String(contentsOf: logFile, encoding: .utf8)
        return logData.split(separator: "\n").suffix(10).joined(separator: "\n")
    }
}

extension ProcessInfo {
    struct CodableProcessInfo: Codable {
        let environment: [String: String]
        let arguments: [String]
        let hostName: String
        let processName: String
        let processIdentifier: Int32
        let operatingSystemVersionString: String
        let processorCount: Int
        let physicalMemory: UInt64
        let systemUptime: TimeInterval
    }
    
    // A method to convert ProcessInfo into a Codable struct
    func codableRepresentation() -> CodableProcessInfo {
        return CodableProcessInfo(
            environment: self.environment,
            arguments: self.arguments,
            hostName: self.hostName,
            processName: self.processName,
            processIdentifier: self.processIdentifier,
            operatingSystemVersionString: self.operatingSystemVersionString,
            processorCount: self.processorCount,
            physicalMemory: self.physicalMemory,
            systemUptime: self.systemUptime
        )
    }
    
    // A method to encode the ProcessInfo
    func encodeToJSON() -> Data? {
        let codableProcessInfo = self.codableRepresentation()
        let encoder = JSONEncoder()
        return try? encoder.encode(codableProcessInfo)
    }
    
    // A method to decode from JSON to ProcessInfo (returns ProcessInfo-like struct)
    static func decodeFromJSON(_ data: Data) -> CodableProcessInfo? {
        let decoder = JSONDecoder()
        return try? decoder.decode(CodableProcessInfo.self, from: data)
    }
}
