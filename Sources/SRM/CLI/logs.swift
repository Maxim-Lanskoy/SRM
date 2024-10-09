//
//  logs.swift
//  Swift Running Manager
//
//  Created by Maxim Lanskoy on 11.09.2024.
//

import ArgumentParser
import Foundation

extension SRM {
    struct Logs: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "View logs of a process.",
            discussion: """
            The `logs` command displays the logs of a managed process.
            
            Examples:
              - View last 10 lines and follow: `srm logs MyApp`
              - View last 50 lines and follow: `srm logs MyApp --lines 50`
              - View logs without following: `srm logs MyApp --no-follow`
              - View logs for all processes: `srm logs all`
            """
        )
        
        @Argument(help: "Name or index of the process to fetch logs for, or 'all' to fetch logs for all processes.")
        var nameOrIndex: String
        
        @Option(name: .shortAndLong, help: "Number of lines to display.")
        var lines: Int = 10
        
        @Flag(name: .shortAndLong, help: "Do not tail logs in real-time.")
        var noFollow: Bool = false
        
        func run() throws {
            if nameOrIndex.lowercased() == "all" {
                try showLogsForAllProcesses()
            } else if let index = Int(nameOrIndex) {
                // Show logs for process by index
                try showLogs(forProcessAtIndex: index)
            } else {
                // Show logs for process by name
                try showLogs(forProcessNamed: nameOrIndex)
            }
        }
        
        func showLogs(forProcessNamed name: String) throws {
            let logFilePath = ProcessManager.logsDirectory.appendingPathComponent("\(name).log").path
            
            if FileManager.default.fileExists(atPath: logFilePath) {
                if !noFollow {
                    // Tail logs in real-time
                    tailLogFile(atPath: logFilePath, processName: name, lines: lines)
                } else {
                    // Only display the specified number of lines
                    let logData = try String(contentsOfFile: logFilePath, encoding: .utf8)
                    let logLines = logData.split(separator: "\n").suffix(lines)
                    
                    print("Last \(lines) lines of logs for \(name):")
                    for line in logLines {
                        print("[\(name)] \(line)")
                    }
                }
            } else {
                print("No logs found for process: \(name)")
            }
        }
        
        func showLogs(forProcessAtIndex index: Int) throws {
            let processInfos = try ProcessManager.fetchAllProcessInfos()
            if index < 1 || index > processInfos.count {
                print("Invalid process index: \(index)")
                return
            }
            
            let processInfo = processInfos[index - 1]
            try showLogs(forProcessNamed: processInfo.processName)
        }
        
        func showLogsForAllProcesses() throws {
            let processInfos = try ProcessManager.fetchAllProcessInfos()
            if processInfos.isEmpty {
                print("No processes found.")
                return
            }
            
            // Create a DispatchGroup to manage concurrent log tailing
            let group = DispatchGroup()
            
            for processInfo in processInfos {
                group.enter()
                DispatchQueue.global().async {
                    defer { group.leave() }
                    do {
                        try self.showLogs(forProcessNamed: processInfo.processName)
                    } catch {
                        print("Failed to show logs for \(processInfo.processName): \(error)")
                    }
                }
            }
            
            group.wait()
        }
        
        func tailLogFile(atPath path: String, processName: String, lines: Int) {
            // Read the last N lines
            if let logData = try? String(contentsOfFile: path, encoding: .utf8) {
                let logLines = logData.split(separator: "\n").suffix(lines)
                for line in logLines {
                    print("[\(processName)] \(line)")
                }
            }
            
            guard let fileHandle = FileHandle(forReadingAtPath: path) else {
                print("Unable to open log file for \(processName).")
                return
            }
            
            // Move to the end of the file
            fileHandle.seekToEndOfFile()
            
            print("Tailing logs for \(processName). Press Ctrl+C to stop.")
            
            // Observe the file for new data
            fileHandle.readabilityHandler = { handle in
                let data = handle.availableData
                if let logEntry = String(data: data, encoding: .utf8) {
                    print("[\(processName)] \(logEntry)", terminator: "")
                }
            }
            
            // Keep the run loop alive
            RunLoop.current.run()
        }
    }
}
