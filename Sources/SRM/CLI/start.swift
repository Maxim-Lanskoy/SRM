//
//  File.swift
//  
//
//  Created by Maxim Lanskoy on 11.09.2024.
//

import ArgumentParser
import Foundation
import ShellOut

extension SRM {
    struct Start: ParsableCommand {
        @Argument(help: "Script, command, or executable to run")
        var executable: String
        
        @Option(name: .shortAndLong, help: "Specify process name")
        var name: String
        
        func run() throws {
            print("Starting process: \(name)")
            
            // Ensure logs directory exists
            try FileManager.default.createDirectory(at: ProcessManager.logsDirectory, withIntermediateDirectories: true, attributes: nil)
            
            let logFilePath = ProcessManager.logsDirectory.appendingPathComponent("\(name).log").path
            
            // Use shellOut to execute the provided command
            let command: String
            if executable.hasPrefix("/") || executable.hasPrefix("./") {
                // If it is a path, treat it as an executable or script
                command = executable
            } else {
                // Otherwise treat it as a shell command
                command = "/bin/bash -c '\(executable)'"
            }
            
            do {
                // Start the process using ShellOut, redirecting output to log file
                _ = try shellOut(
                    to: command,
                    at: ".",
                    outputHandle: FileHandle(forWritingAtPath: logFilePath),
                    errorHandle: FileHandle(forWritingAtPath: logFilePath)
                )
                
                // Get the PID of the process
                let pid = getProcessPID(for: executable)
                
                // Save the process info (name and PID) in a JSON file
                let processInfo = ProcessInfo.processInfo.codableRepresentation()
                try ProcessManager.saveProcessInfo(processInfo)
                
                print("Process \(name) started with PID: \(pid)")
            } catch {
                print("Failed to start process: \(error)")
            }
        }
        
        // Helper function to get PID of a running process by executable name
        private func getProcessPID(for executable: String) -> Int {
            let command = "pgrep -f \(executable)"
            do {
                let pidOutput = try shellOut(to: command)
                return Int(pidOutput.trimmingCharacters(in: .whitespacesAndNewlines)) ?? -1
            } catch {
                print("Failed to get PID: \(error)")
                return -1
            }
        }
    }
}
