//
//  minotor.swift
//  Swift Running Manager
//
//  Created by Maxim Lanskoy on 10.10.2024.
//

import ArgumentParser
import Foundation
import ShellOut

extension SRM {
    struct Monitor: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Start the SRM monitoring service")

        func run() throws {
            print("Starting SRM monitoring service...")
            
            while true {
                // Fetch all process info files
                let processInfos = try ProcessManager.fetchAllProcessInfos()
                
                for var processInfo in processInfos {
                    if processInfo.status == "error" || processInfo.status == "stopped" {
                        // Skip processes that are in error or stopped state
                        continue
                    }
                    
                    if let pid = processInfo.processIdentifier, !isProcessRunning(pid: pid) {
                        if processInfo.restart {
                            print("Process \(processInfo.processName) has stopped. Restarting...")
                            // Restart the process
                            try restartProcess(processInfo: &processInfo)
                        } else {
                            // Update process info to set status to "stopped" and remove pid and startTime
                            processInfo.status = "stopped"
                            processInfo.processIdentifier = nil
                            processInfo.startTime = nil
                            try ProcessManager.saveProcessInfo(processInfo)
                            print("Process \(processInfo.processName) has stopped and will not be restarted.")
                        }
                    }
                }
                
                // Sleep for 5 seconds before the next check
                Thread.sleep(forTimeInterval: 5)
            }
        }
        
        func restartProcess(processInfo: inout CodableProcessInfo) throws {
            let name = processInfo.processName
            let executable = processInfo.executable
            let logFilePath = processInfo.logFilePath
            
            // Build the command to start the process with nohup and redirect output to log file
            let command = """
            nohup stdbuf -oL \(executable) > \(logFilePath) 2>&1 & echo $! && disown
            """
            
            do {
                // Run the command and capture the output (PID)
                let output = try shellOut(to: command)
                let pidString = output.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                guard let pid = Int32(pidString) else {
                    throw RuntimeError("Failed to retrieve PID of the restarted process.")
                }
                
                // Update process info with new PID, start time, and status
                processInfo.processIdentifier = pid
                processInfo.startTime = Date()
                processInfo.status = "running"
                try ProcessManager.saveProcessInfo(processInfo)
                
                print("Process \(name) restarted with PID: \(pid).")
            } catch {
                print("Failed to restart process \(name): \(error)")
                // Update process info status to "error"
                processInfo.status = "error"
                processInfo.processIdentifier = nil
                processInfo.startTime = nil
                try ProcessManager.saveProcessInfo(processInfo)
            }
        }

        func isProcessRunning(pid: Int32) -> Bool {
            return kill(pid, 0) == 0
        }
    }
}
