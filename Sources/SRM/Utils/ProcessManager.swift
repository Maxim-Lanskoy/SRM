//
//  ProcessManager.swift
//  Swift Running Manager
//
//  Created by Maxim Lanskoy on 11.09.2024.
//

import Foundation

struct CodableProcessInfo: Codable {
    let processName: String
    let processIdentifier: Int32
    let startTime: Date
    let restart: Bool
    let executable: String
    let logFilePath: String
}

struct ProcessManager {
    static let logsDirectory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".srm/logs")

    static func saveProcessInfo(_ process: CodableProcessInfo) throws {
        let data = try JSONEncoder().encode(process)
        let filePath = logsDirectory.appendingPathComponent("\(process.processName).json")
        try data.write(to: filePath)
    }

    static func fetchProcessInfo(for name: String) throws -> CodableProcessInfo? {
        let filePath = logsDirectory.appendingPathComponent("\(name).json")
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            return nil
        }
        let data = try Data(contentsOf: filePath)
        return try JSONDecoder().decode(CodableProcessInfo.self, from: data)
    }

    static func removeProcessInfo(for name: String) throws {
        let filePath = logsDirectory.appendingPathComponent("\(name).json")
        if FileManager.default.fileExists(atPath: filePath.path) {
            try FileManager.default.removeItem(at: filePath)
        }
    }

    static func fetchAllProcessInfos() throws -> [CodableProcessInfo] {
        let files = try FileManager.default.contentsOfDirectory(at: logsDirectory, includingPropertiesForKeys: nil)
        let jsonFiles = files.filter { $0.pathExtension == "json" }
        var processInfos: [CodableProcessInfo] = []

        for file in jsonFiles {
            let data = try Data(contentsOf: file)
            if let processInfo = try? JSONDecoder().decode(CodableProcessInfo.self, from: data) {
                processInfos.append(processInfo)
            }
        }
        return processInfos
    }
}
