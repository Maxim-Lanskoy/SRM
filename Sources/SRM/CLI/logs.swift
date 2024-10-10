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
                // Adjust index for zero-based array
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
                    // Display the specified number of lines before tailing
                    displayLastLines(of: logFilePath, processName: name, lines: lines)
                    // Tail logs in real-time
                    tailLogFile(atPath: logFilePath, processName: name)
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
            
            let processInfo = processInfos[index - 1] // Adjust for zero-based index
            try showLogs(forProcessNamed: processInfo.processName)
        }
        
        func showLogsForAllProcesses() throws {
            let processInfos = try ProcessManager.fetchAllProcessInfos()
            if processInfos.isEmpty {
                print("No processes found.")
                return
            }
            
            var allLogEntries: [(timestamp: Date, processName: String, line: String)] = []

            // Collect log entries from all processes
            for processInfo in processInfos {
                let logFilePath = ProcessManager.logsDirectory.appendingPathComponent("\(processInfo.processName).log").path
                if FileManager.default.fileExists(atPath: logFilePath) {
                    if let logData = try? String(contentsOfFile: logFilePath, encoding: .utf8) {
                        let logLines = logData.split(separator: "\n").suffix(lines)
                        for line in logLines {
                            if let timestamp = extractTimestamp(from: line) {
                                allLogEntries.append((timestamp, processInfo.processName, String(line)))
                            }
                        }
                    }
                }
            }
            
            // Sort all entries by timestamp
            allLogEntries.sort { $0.timestamp < $1.timestamp }

            // Display sorted log entries
            for entry in allLogEntries {
                print("[\(entry.processName)] \(entry.line)")
            }

            if !noFollow {
                // Start tailing logs in real-time for all processes
                tailLogsForAllProcesses(processInfos: processInfos)
            }
        }
        
        func extractTimestamp(from logLine: Substring) -> Date? {
            let timestampPattern = "\\[([^\\]]+)\\]"
            if let regex = try? NSRegularExpression(pattern: timestampPattern, options: []),
               let match = regex.firstMatch(in: String(logLine), options: [], range: NSRange(location: 0, length: logLine.count)) {
                let timestampRange = match.range(at: 1)
                if let timestampString = Range(timestampRange, in: logLine) {
                    let timestamp = String(logLine[timestampString])
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    return dateFormatter.date(from: timestamp)
                }
            }
            return nil
        }
        
        func tailLogsForAllProcesses(processInfos: [CodableProcessInfo]) {
            var fileHandles: [FileHandle: String] = [:]
            
            for processInfo in processInfos {
                let logFilePath = ProcessManager.logsDirectory.appendingPathComponent("\(processInfo.processName).log").path
                if FileManager.default.fileExists(atPath: logFilePath) {
                    if let fileHandle = FileHandle(forReadingAtPath: logFilePath) {
                        // Move to the end of the file for real-time tailing
                        fileHandle.seekToEndOfFile()
                        fileHandles[fileHandle] = processInfo.processName
                    } else {
                        print("Unable to open log file for \(processInfo.processName).")
                    }
                }
            }
            
            // Use a unified dispatch source to read data from all file handles
            let queue = DispatchQueue(label: "com.srm.logs.all", qos: .utility)
            
            for (fileHandle, processName) in fileHandles {
                fileHandle.readabilityHandler = { handle in
                    let data = handle.availableData
                    if let logEntry = String(data: data, encoding: .utf8), !logEntry.isEmpty {
                        queue.async {
                            print("[\(processName)] \(logEntry)", terminator: "")
                        }
                    }
                }
            }
            
            // Keep the run loop alive indefinitely to continue tailing all logs
            print("Tailing logs for all processes. Press Ctrl+C to stop.")
            dispatchMain()
        }
        
        func displayLastLines(of filePath: String, processName: String, lines: Int) {
            if let logData = try? String(contentsOfFile: filePath, encoding: .utf8) {
                let logLines = logData.split(separator: "\n").suffix(lines)
                for line in logLines {
                    print("[\(processName)] \(line)")
                }
            }
        }
        
        func tailLogFile(atPath path: String, processName: String) {
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
