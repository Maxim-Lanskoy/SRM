//
//  start.swift
//  Swift Running Manager
//
//  Created by Maxim Lanskoy on 11.09.2024.
//

import ArgumentParser
import Foundation
import ShellOut

extension SRM {
    struct Start: ParsableCommand {        
        static let configuration = CommandConfiguration(
            abstract: "Start a new process managed by SRM.",
            discussion: """
            The `start` command allows you to run any executable, script, or command as a managed process.

            Examples:
              - Start a Swift app: `srm start /path/to/app --name MyApp`
              - Start a shell script: `srm start ./script.sh --name MyScript`
              - Start a command: `srm start "python script.py" --name PythonScript`

            Options:
              - Start all stopped processes: `srm start all`
              - You can specify a custom name using `--name`.
              - Use `--restart` to automatically restart the process if it crashes.
            """
        )

        @Argument(help: "The script, command, or executable to run, or 'all' to start all stopped processes.")
        var executableOrName: String?
        
        @Option(name: .shortAndLong, help: "Specify a custom name for the process.")
        var name: String?
        
        @Flag(name: .shortAndLong, help: "Automatically restart the process if it exits unexpectedly.")
        var restart: Bool = false
        
        func run() throws {
            if executableOrName?.lowercased() == "all" {
                try startAllProcesses()
            } else if let executable = executableOrName {
                // Start a new process with the provided executable
                try startProcess(executable: executable, name: name, restart: restart)
            } else {
                print("Please provide an executable to start or 'all' to start all stopped processes.")
            }
        }
        
        func startProcess(executable: String, name: String?, restart: Bool) throws {
            let processName = name ?? URL(fileURLWithPath: executable).lastPathComponent
            print("Starting process: \(processName)")
            
            // Ensure logs directory exists
            try FileManager.default.createDirectory(at: ProcessManager.logsDirectory, withIntermediateDirectories: true, attributes: nil)
            
            let logFilePath = ProcessManager.logsDirectory.appendingPathComponent("\(processName).log").path
            
            // Rotate log if it exceeds size limit (e.g., 5 MB)
            let maxLogSize: UInt64 = 5 * 1024 * 1024 // 5 MB
            if let attributes = try? FileManager.default.attributesOfItem(atPath: logFilePath),
               let fileSize = attributes[FileAttributeKey.size] as? UInt64,
               fileSize > maxLogSize {
                // Move current log to archived log with timestamp
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMddHHmmss"
                let timestamp = dateFormatter.string(from: Date())
                let archivedLogPath = ProcessManager.logsDirectory.appendingPathComponent("\(processName)_\(timestamp).log")
                try FileManager.default.moveItem(atPath: logFilePath, toPath: archivedLogPath.path)
                print("Rotated log file to \(archivedLogPath.lastPathComponent)")
            }
            
            // Build the command to start the process with nohup and redirect output to log file
            let command = "nohup \(executable) >> \(logFilePath) 2>&1 & echo $!"
            
            do {
                // Run the command and capture the output (PID)
                let output = try shellOut(to: command)
                let pidString = output.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                guard let pid = Int32(pidString) else {
                    throw RuntimeError("Failed to retrieve PID of the started process.")
                }
                
                // Save process info with status "running"
                let processInfo = CodableProcessInfo(
                    processName: processName,
                    processIdentifier: pid,
                    startTime: Date(),
                    restart: restart,
                    executable: executable,
                    logFilePath: logFilePath,
                    status: "running"
                )
                try ProcessManager.saveProcessInfo(processInfo)
                
                print("Process \(processName) started with PID: \(pid).")
            } catch {
                print("Failed to start process \(processName): \(error)")
                // Save process info with status "error"
                let processInfo = CodableProcessInfo(
                    processName: processName,
                    processIdentifier: nil,
                    startTime: nil,
                    restart: restart,
                    executable: executable,
                    logFilePath: logFilePath,
                    status: "error"
                )
                try ProcessManager.saveProcessInfo(processInfo)
            }
        }
        
        func startAllProcesses() throws {
            let processInfos = try ProcessManager.fetchAllProcessInfos()
            let stoppedProcesses = processInfos.filter { $0.status == "stopped" || $0.status == "error" }
            
            if stoppedProcesses.isEmpty {
                print("No stopped processes to start.")
                return
            }
            
            for processInfo in stoppedProcesses {
                try startProcess(executable: processInfo.executable, name: processInfo.processName, restart: processInfo.restart)
            }
        }
    }
}
